inherit SpeedyDelivery.Plugin;
import Tools.Logging;

constant name = "list name in subject";
constant description = "inserts the list name into the subject of a list";
constant list_enableable = 1;

int _enabled = 1;

mapping query_event_callers()
{
  return ([ "rewriteMessage" : rewrite_subject ]);
}

mapping query_destination_callers()
{
  return ([ ]);
}

int rewrite_subject(string eventname, mapping event, mixed ... args)
{
   Log.debug("rewriting subject for message: " + event->mime->subject);
   string s = "[" + event->request->list["name"] + "]";

   if(search(event->mime->headers->subject, s) == -1)
    event->mime->headers->subject = s + " " + event->mime->headers->subject;

   return SpeedyDelivery.ok;
}
