inherit Fins.SMTPProcessor;

int|array _cb_data(object mime, string sender, array|string recipient,
                     void|string raw)
{
write(sprintf("smtpd: mailfrom=%O, to=%O, headers=%O\ndata=%s\n", sender,
                recipient, mime->headers, mime->getdata()));
// check the data and deliver the mail here
if(mime->body_parts)
{
   foreach(mime->body_parts, object mpart) write(sprintf("smtpd: mpart data = %O\n", mpart->getdata()));
}
  return 250;
}


