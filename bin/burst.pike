/*
 *  Bursts an RFC 934 Digest into individual files.
 *  
 *  Usage:  burst.pike digest_file outputbasename
 *
 */

int main(int argc, array argv)
{
  String.Buffer current_message;
  int num = 1;
  if(argc < 3) 
  {
    exit(1, "usage: burst digest_file output_basename \n");
  }

  Stdio.File f = Stdio.File(argv[1], "r");
  string basename = argv[2];
  object i = f->line_iterator();
  int lineno;
  foreach(i;; string l)
  {
    if(has_prefix(l, "------- "))
    {
      if(current_message)
      {
        string msgf = sprintf(basename + ".%03d", num++);
        Stdio.write_file(msgf, (string)current_message);
        werror("wrote " + msgf + "\n"); 
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
