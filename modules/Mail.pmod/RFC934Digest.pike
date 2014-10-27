//! Bursts an RFC 934 Digest into individual files.


//! @returns
//!   0 to continue processing; otherwise stops bursting operation.
function(string,int,mixed...:int) message_callback;

//!
//! @param message_callback
//!   function with signature function(string,int,mixed...:int).
void burst(Stdio.File input, function message_callback, mixed ... args)
{
  String.Buffer current_message;
  int num = 1;

  object i = input->line_iterator();
  int lineno;
  foreach(i;; string l)
  {
    if(has_prefix(l, "------- "))
    {
      if(current_message)
      {
        if(message_callback((string)current_message, num++, @args)) return;
      }
      current_message = String.Buffer();
      i->next();
    }
    else if(current_message && has_prefix(l, "- ------- "))
    {
      if(lineno)
        current_message->add("\n");
      current_message->add(l[2..]);
      lineno++;
    }
    else if(current_message) 
    {
      if(lineno)
        current_message->add("\n");
      current_message->add(l);
      lineno++;
    }
  }
  return 0;
}
