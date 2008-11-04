inherit Fins.SMTPProcessor;

import Tools.Logging;

object log = Tools.Logging.get_logger("exceptions");

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

  werror("returning %d\n", res);
  return res||250;
}

int|array handle_message(SpeedyDelivery.Request request)
{
  Log.info("smtp_processor: handling message for list %O, function %O", request->list, request->functionname||"");

  if(request->functionname)
  {
    mixed e;
    e = catch(app->destination_handlers[request->functionname](request));

    if(e)
      log->exception("smtp processor intercepted an error.", e); 

    return 250;
  }
  else
    return 550;
}

int check_destination(string addr)
{
  Mail.MailAddress a;

  if(catch(a = Mail.MailAddress(addr)))
    return 0;

  if(app->is_valid_address(a))
    return 1;
  

  return 0;
}
