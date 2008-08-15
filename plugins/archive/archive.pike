inherit SpeedyDelivery.Plugin;
import Tools.Logging;

constant name = "archive support";
constant description = "support for archived article storage";

int _enabled = 1;

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
   m["subject"] = event->mime->headers->subject;
   m["content"] = (string)event->mime;
   m->save();

   return SpeedyDelivery.ok;
}
