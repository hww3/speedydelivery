inherit Fins.Request;

MIME.Message mime;
Mail.MailAddress sender;
Mail.MailAddress recipient;
string raw;
object smtp;

string list_address;
object list;
string functionname;

static void create(Fins.Application _app, object _mime, string _sender, string _recipient,
                     void|string _raw, object|void _smtp)
{
  fins_app = _app;
  smtp = _smtp;
  mime = MIME.Message((string)_mime);
  sender = Mail.MailAddress(_sender);
  recipient = Mail.MailAddress(_recipient);  

  raw = _raw;


  populate_fields();
}

void populate_fields()
{
  array x = fins_app->is_valid_address(recipient);
  if(!x) throw(Error.Generic(sprintf("invalid list address %O\n", recipient)));

  list = fins_app->get_list(x[0]);
  if(!list) 
    throw(Error.Generic(sprintf("unknown list %O\n", x[0])));

  list_address = sprintf("%s@%s", list["name"], fins_app->getmyhostname());
  functionname = x[1];
}
