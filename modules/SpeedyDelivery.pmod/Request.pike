inherit Fins.Request;

MIME.Message mime;
Mail.MailAddress sender;
array(Mail.MailAddress) recipients;
string raw;
object smtp;

static void create(Fins.Application _app, object _mime, string _sender, array|string _recipient,
                     void|string _raw, object _smtp)
{
  fins_app = _app;
  smtp = _smtp;
  mime = _mime;
  sender = Mail.MailAddress(_sender);
  if(stringp(_recipient))
    recipients = ({ Mail.MailAddress(_recipient) });
  else 
    recipients = map(_recipient, Mail.MailAddress);  

  raw = _raw;
}

