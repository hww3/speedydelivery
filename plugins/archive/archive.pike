inherit SpeedyDelivery.Plugin;
import Tools.Logging;

constant name = "archive support";
constant description = "support for archived article storage";

int _enabled = 1;
int checked_exists = 0;

mapping query_event_callers()
{
  return ([ "preDelivery" : archive_message ]);
}

mapping query_destination_callers()
{
  return ([ ]);
}

int archive_message(string eventname, mapping event, mixed ... args)
{
   SpeedyDelivery.Objects.Archived_message m;
   m = SpeedyDelivery.Objects.Archived_message();
   m["List"] = event->request->list;
   m["envelope_from"] = (string)event->request->sender;
   m["messageid"] = (string)event->request->mime->headers["message-id"];
   if(event->request->mime->headers["in-reply-to"])
     m["referenceid"] = (string)event->request->mime->headers["in-reply-to"];
   m["subject"] = event->mime->headers->subject;
   m["content"] = (string)event->mime;
   m->save();

   updateIndex(eventname, event, m);

   return SpeedyDelivery.ok;
}

int updateIndex(string eventname, mapping event, object message)
{
  call_out(Thread.Thread, 0, doUpdateIndex, eventname, event, message);

  return 0;
}

void doUpdateIndex(string eventname, mapping event, object message)
{
  mapping p = app->config["full_text"];
  if(!p)
  {
     Log.debug("no full text configuration, skipping.");
     return;
  }

  if(!p["url"])
  {
    Log.debug("no full text url provided, skipping.");
    return;
  }

  object c = Protocols.XMLRPC.Client(p["url"] + "/update/");

  string indexname = "SpeedyDelivery_" + event->request->list["name"];

  if(!checked_exists)
  {
    int e = c["exists"](indexname)[0];
    if(!e)
      c["new"](indexname);
    checked_exists = 1;
  }

  int t;
  t = time();
  t = Calendar.dwim_time(event->request->mime->headers->date)->unix_time();

  string content = Tools.String.textify(event->request->mime->getdata());
  c["add"](indexname, event->request->mime->headers->subject, 
      t, content,
      (string)message["id"],
      Tools.String.make_excerpt(content),      
      "text/mime-message");
}


