inherit Fins.SMTPProcessor;

import Tools.Logging;

int havesent;

int|array _cb_rcptto(string addr)
{
  Log.debug("smtp_processor: mailto=%O", addr);
  if(!check_destination(addr))
    return 550;
  else
    return 250;
}

int|array _cb_data(object mime, string sender, array|string recipient,
                     void|string raw)
{
  Log.debug("smtp_processor: mailfrom=%O, to=%O, headers=%O\ndata=%s", sender,
                recipient, mime->headers, mime->getdata());

  SpeedyDelivery.Request rq;
  int res;

  if(stringp(recipient))
    recipient = ({ recipient });

//  if(havesent) return 250;

  foreach(recipient;; string r)
  {
    havesent++;

    rq = SpeedyDelivery.Request(app, mime, sender, r, raw, smtp);
    int res1 = handle_message(rq);
    if(res1 > res) res = res1;
  }

  return res;
}

int|array handle_message(SpeedyDelivery.Request request)
{
  Log.info("smtp_processor: handling message for list %O, function %O", request->list, request->functionname||"");

  if(request->functionname)
  {
    app->destination_handlers[request->functionname](request);
  }
  else
    return 550;
}

int check_destination(string addr)
{
  Mail.MailAddress a;

  if(catch(a = Mail.MailAddress(addr)))
    return 0;

  a->localpart = lower_case(a->localpart);

  if(is_valid_address(a))
    return 1;
  

  return 0;
}

int is_valid_address(Mail.MailAddress a)
{
  // if we already know that the address is okay, we just go with it.
  array r;
  if(r = app->valid_addresses[a->localpart])
  {
     Log.debug("list: %O, function: %O", r[0], r[1]);
     return 1;
  }
  // otherwise, we need to figure it out.
  // list addresses look like this: listname(-functionname)
  // where listname cannot contain ("-" + any registered functionname).
  array x = a->localpart/"-";

  string functionname;

  if(sizeof(x) > 1) // okay, we have a -, we need to figure if it's 
                    // part of the list name, or an admin function.
  {
    if(app->destination_handlers[x[-1]])
    {
       functionname = x[-1];
       x = x[0.. sizeof(x) - 2];
    }
  }

  object l;

  if(catch(l = Fins.Model.find.lists_by_alt(x*"-")))
  {
    Log.info("%s is not a valid list identifier.", a->localpart);
    return 0;
  }

  Log.debug("list: %O, function: %O", l["name"], functionname);

  app->valid_addresses[a->localpart] = ({l["name"], functionname});
  
  return 1;
}
