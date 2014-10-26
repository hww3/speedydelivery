inherit Fins.Util.AppTool;

int run(mixed ... args)
{
  string list;

  if(sizeof(args) < 2)
  {
    werror("usage: import listname message [message2 ... messageN]\n");
    return 1;
  }

  list = args[0];
  

  foreach(args[1..];; string fn)
  {
    object rq;
    object mime;
    string sender;
    string recipient;

    string f;
    catch(f = Stdio.read_file(fn));
    if(!f)
    { 
      werror("import: unable to read file %O\n", fn);
      return 2;
    }
    mime = MIME.Message(f);
    sender = mime->headers->from;
    recipient = mime->headers->to;

    rq = SpeedyDelivery.Request(app, mime, sender, recipient, 0, 0);
  }
  
}
