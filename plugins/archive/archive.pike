inherit SpeedyDelivery.Plugin;
import Tools.Logging;

constant name = "archive support";
constant description = "support for archived article storage";

int _enabled = 1;
mapping checked_exists = ([]);

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
Log.info("archiving message");
   SpeedyDelivery.Objects.Archived_message m;
   m = SpeedyDelivery.Objects.Archived_message();
   m["List"] = event->request->list;
   m["envelope_from"] = (string)event->request->sender;

   // the envelope_from address almost never includes a nice name.
   if(event->mime && event->mime->headers->from)
   {
     object addr;
     catch(addr = Mail.MailAddress(event->mime->headers->from));
     if(addr)
      m["envelope_from"] = (string)addr;
   }
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
  Thread.Thread(doUpdateIndex, eventname, event, message);

  return 0;
}

void doUpdateIndex(string eventname, mapping event, object message)
{
Log.info("doUpdateIndex");
  mapping p = app->config["full_text"];
  if(!p)
  {
     Log.info("no full text configuration, skipping.");
     return;
  }

  if(!p["url"])
  {
    Log.info("no full text url provided, skipping.");
    return;
  }
Log.info("getting client: %O, %O.", event, p);
  string indexname = "SpeedyDelivery_" + event->request->list["name"];
Log.info("index name: %O", indexname);
  object c;
object e = catch(c = FullText.UpdateClient(p["url"], indexname, p["auth"], 1));
Log.info("got client: %O.", e);

Log.info("index ready.");
  object t = Calendar.dwim_time(event->request->mime->headers->date);

  string content;
   content = Tools.String.textify(
                SpeedyDelivery.getfullbodytext(event->request->mime, content));
    Log.info("submitting message %O for indexing.", message);

  c->add(event->request->mime->headers->subject, 
      t, content,
      (string)message["id"],
      Tools.String.make_excerpt(content),      
      "text/mime-message");
}


