inherit Fins.SMTPProcessor;

import Tools.Logging;

int|array _cb_data(object mime, string sender, array|string recipient,
                     void|string raw)
{
  Log.debug("smtpd: mailfrom=%O, to=%O, headers=%O\ndata=%s\n", sender,
                recipient, mime->headers, mime->getdata());

  SpeedyDelivery r = SpeedyDelivery.Request(app, mime, sender, recipient, raw, smtp);

  return handle_message(r);

}

int|array handle_message(SpeedyDelivery.Request request)
{
  return 250;
}