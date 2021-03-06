inherit Fins.Util.AppTool;

int burst_mode = 0;

int run(mixed ... args)
{
  string list;
  array nargs = ({});

  foreach(args;; string arg)
  {
    if(arg == "-b") burst_mode = 1;
    else nargs += ({arg});
  }

  if(sizeof(args) < 2)
  {
    werror("usage: import listname [-b] message [message2 ... messageN]\n");
    return 1;
  }


  args = nargs;
 
  list = args[0];  

  foreach(args[1..];; string fn)
  {
    object f;
    catch(f = Stdio.File(fn, "r"));
    if(!f)
    { 
      werror("import: unable to open file %O\n", fn);
      return 2;
    }

    if(burst_mode)
    {
      object burster = Mail.RFC934Digest();
      burster->burst(f, import_message, list);
    }
    else
    {
      string x = Stdio.read_file(fn);
      return import_message(x, 0, list);
    }
  }

sleep(5);  
}

int import_message(string file, int num, string list)
{
    object rq;
    object mime;
    string sender;
    string recipient;
    mixed err;


    mime = MIME.Message(String.trim_all_whites(file));
    sender = mime->headers->from;
    recipient = list + "@localhost";
    werror("importing message %O\n", num);
    
    err = catch(rq = SpeedyDelivery.Request(app, mime, sender, recipient, 0, 0));
    if(err)
    {
      werror("error: %s\n", Error.mkerror(err)->message());
      werror(master()->describe_backtrace(Error.mkerror(err)->backtrace()));
    }

    int res = app->trigger_event("preDelivery",
             (["request": rq, "mime": rq->mime, "list": rq->list]));
     if(res == SpeedyDelivery.abort) return 1;
     else return 0;
}
