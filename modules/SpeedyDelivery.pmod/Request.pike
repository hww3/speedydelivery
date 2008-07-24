inherit Fins.Request;

MIME.Message mime;
Mail.MailAddress sender;
Mail.MailAddress recipient;
string raw;
object smtp;

object list;
string functionname;

static void create(Fins.Application _app, object _mime, string _sender, string _recipient,
                     void|string _raw, object _smtp)
{
  fins_app = _app;
  smtp = _smtp;
  mime = _mime;
  sender = Mail.MailAddress(_sender);
  recipient = Mail.MailAddress(_recipient);  

  raw = _raw;

  populate_fields();
}

void populate_fields()
{
  array x = fins_app->valid_addresses[recipient->localpart];

  list = Fins.Model.find.lists_by_alt(x[0]);
  functionname = x[1];
}
