inherit SpeedyDelivery.Plugin;

import Tools.Logging;

constant name = "bounce support";
constant description = "support for handling bounces";

int _enabled = 1;

/*
   some regular expressions we've shamelessly borrowed from
   smartlist's etc/rc.request
*/

constant transient_bounce_subject = 
"(Warning - delayed mail|(WARNING: message ([^      ]+ )?|Mail )delayed|"
"(Returned mail: )?(warning: c(an|ould )not send m(essage fo|ail afte)r|Unbalanced '\"'|"
"Cannot send (within [0-9]|8-bit data to 7-bit)|"
"Data format error|Headers too large|Eight bit data not allowed|"
"Message (size )?exceeds (fixed )?maximum (fixed|message) size)|"
"Undeliverable (RFC822 )?mail: temporarily unable to deliver|"
"\\*\\*\\* WARNING - Undelivered mail in mailqueue|Execution succee?ded)";

constant warning_subject =
"(Warning from|mail warning| ?Waiting mail)";

constant warning_senders =
".*(uucp|mmdf)";

constant warning_removed = 
"You have been removed from";

constant x_loop_bounce =
"\(bounce\)";

mapping query_destination_callers()
{
  return (["bounces": handle_bounce]);
}

int handle_bounce(SpeedyDelivery.Request r)
{
  Log.info("the following bounce was received: %O", r->mime->headers);
  string bouncer;
  array bouncers;
  int handled;

  if(is_bounce(r))
  {
    bouncer = extract_bouncer(r);
  }
  else if(is_dsn(r))
  {
    bouncers = extract_bouncer_from_dsn(r);
//    werror("bouncers: %O\n", bouncers);
    bouncers = Fins.Model.find.subscribers((["email": Fins.Model.InCriteria(bouncers)]));
    werror("bouncers: %O\n", bouncers);
    // if we have more than hit, it's probably ambiguous.
    if(sizeof(bouncers) == 1)
    {
      bouncers->has_bounced(r->list);
      handled++;
    }
  }

  if(!handled)
  {
//  else // misdirected messages should go to the list owner.
    string subject = "Unhandled bounce message for " + r->list["name"];
    string message = "A message was sent to this list's bounce address,\n "
                           "however we weren't able to identify it as a bounce. \n"
                           "Please examine it and if necessary, manually unsubscribe\n"
                           "the user in question.\n\n";

    app->send_message_as_attachment_to_list_owner(r->list, subject, message, r->mime);
  }

  Stdio.write_file("/tmp/spdbounce.txt", (string)r->mime);
  return 0;
}

string extract_bouncer(SpeedyDelivery.Request r)
{ 
  string bouncer;
  string u,h;
  string d = r->mime->getdata();
  int matches;
  Log.debug("extracting bouncer.");

  do
  {
    matches = sscanf(d, "%*s %s@%s[ \\r\\n]%s", u, h, d); 
    if(matches >= 3)
      Log.debug("got an address: %s@%s\n", u, h);
  }
  while(d && sizeof(d) && matches == 4);
  return bouncer;
}

array extract_bouncer_from_dsn(SpeedyDelivery.Request r)
{ 
  array bouncers = ({});
  string u,h;
  string d = SpeedyDelivery.getfullbodymimetext(r->mime, "message/delivery-status");
  Log.debug("extracting bouncer from dsn.");
  int matches;
  object rx = Regexp.SimpleRegexp(".*[ \t\r\n\<;](.*@.*)[ \\t\\r\\n\\>].*");
  foreach(d/"\n";; string l)
  {
    array x = rx->split(l);
    if(x)
    {
      bouncers += ({x[0]});
    }
  }
  return Array.uniq(bouncers);
}

int is_dsn(SpeedyDelivery.Request r)
{
  if(has_prefix(r->mime->headers["content-type"], "multipart/report")) 
  {
    Log.debug("match on multipart_report");
    return 1;
  }

  if(r->mime->body_parts)
  {
    foreach(r->mime->body_parts;; object bp)
    {
       if(has_prefix(bp->headers["content-type"], "multipart/report")) 
       {
         Log.debug("match on subpart multipart_report");
         return 1;
       }

       if(has_prefix(bp->headers["content-type"], "message/delivery-status")) 
       {
         Log.debug("match on subpart delivery_status");
         return 1;
       }
    }
  }    
  return 0;
}

int is_bounce(SpeedyDelivery.Request r)
{
  object regexp = Regexp.SimpleRegexp(transient_bounce_subject);

  if(regexp->match(r->mime->headers["subject"]))
  {
    Log.debug("match on transient_bounce_subject");
    return 1;
  }

  regexp = Regexp.SimpleRegexp(warning_senders);
  if(regexp->match(r->mime->headers["from"]))
  {
    Log.debug("match on warning_senders");
    return 1;
  }
  if(regexp->match(r->mime->headers["sender"]||""))
  {
    Log.debug("match on warning_senders");
    return 1;
  }

  regexp = Regexp.SimpleRegexp(warning_subject);
  if(regexp->match(r->mime->headers["subject"]))
  {
    Log.debug("match on warning_subject");
    return 1;
  }

  regexp = Regexp.SimpleRegexp(warning_removed);
  if(regexp->match(r->mime->headers["subject"]))
  {
    Log.debug("match on warning_removed");
    return 1;
  }

  regexp = Regexp.SimpleRegexp(x_loop_bounce);
  if(regexp->match(r->mime->headers["x-loop"]||""))
  {
    Log.debug("match on x_loop_bounce");
    return 1;
  }

  return 0;
}
