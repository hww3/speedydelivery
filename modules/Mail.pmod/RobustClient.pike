import Tools.Logging;

inherit Protocols.SMTP.Client;

  static int cmd(string c, string|void comment)
  {
    int r = command(c);
/*
    switch(r) {
    case 200..499:
      break;
    default:
      error( "SMTP: "+c+"\n"+(comment?"SMTP: "+comment+"\n":"")+
             "SMTP: "+Protocols.SMTP.replycodes[r]+"\n" );
    }
*/
    return r;
  }


  int|array(string) send_message(string from, array(string) to, string body)
  {
    array failures = ({});
    int rv;

    array qi = create_queue_items(from, to, body);

    rv = cmd("MAIL FROM: <" + from + ">");
    Log.debug("got " + rv + " on MAIL FROM");

    if(rv > 400 && rv < 499) // temporary failure, retry later.
    {
        qi->set_atomic((["last_attempt": Calendar.now()->second(),
                      "in_progress":  0 ]));
        return 0;
    }

    foreach(qi, object i) 
    {
      rv = cmd("RCPT TO: <" + i["envelope_to"] + ">");
      Log.debug("got " + rv + " on RCPT TO");
      if(rv >= 500) // permanent failure
      {
        failures += ({ i["envelope_to"] });
        qi -= ({i});
        i->delete();
        continue;
      }
      else if(rv >= 400 && rv <= 499) // temporary failure
      {
        i->set_atomic((["last_attempt": Calendar.now()->second(),
                      "in_progress":  0 ]));
        qi -= ({i});
        continue;
      }
      else
      {
      }
    }

    rv = cmd("DATA");

    Log.debug("got " + rv + " on DATA");
    if(rv >= 500) // permanent failure
    {
      failures += qi["envelope_to"];
      qi->delete();
    }
    else if(rv >= 400 && rv <= 499) // temporary failure
    {     
      qi->set_atomic((["last_attempt": Calendar.now()->second(),
                      "in_progress":  0 ]));
    }

    // Perform quoting according to RFC 2821 4.5.2.
    if (sizeof(body) && body[0] == '.') {
      body = "." + body;
    }
    body = replace(body, "\r\n.", "\r\n..");

    // RFC 2821 4.1.1.4:
    //   An extra <CRLF> MUST NOT be added, as that would cause an empty
    //   line to be added to the message.
    if (has_suffix(body, "\r\n"))
      body += ".";
    else
      body += "\r\n.";

    rv = cmd(body);
    Log.debug("got " + rv + " on DATA BODY");
    if(rv >= 500) // permanent failure
    {
      failures += qi["envelope_to"];
      qi->delete();
    }
    else if(rv >= 400 && rv <= 499) // temporary failure
    {     
      qi->set_atomic((["last_attempt": Calendar.now()->second(),
                      "in_progress":  0 ]));
    }
    else // success!
    { 
      qi->delete();
    }

    rv = cmd("QUIT");
    if(sizeof(failures)) return failures;
    else return 0;
  }

  array create_queue_items(string from, array(string) to, string body)
  {
    array(object) qi = allocate(sizeof(to));

    foreach(to; int i; string t)
    {
      mapping vals = ([]);
      vals->envelope_from = from;
      vals->envelope_to = t;
      vals->content = body;
      vals->in_progress = 1;
      vals->queued = Calendar.now()->second();
      vals->last_attempt = vals->queued;

      qi[i] = SpeedyDelivery.Objects.Outbound_message();
      qi[i]->set_atomic(vals);
//      qi[i]->save();
    } 
 
    return qi;
  }
