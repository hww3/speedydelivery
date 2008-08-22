inherit SpeedyDelivery.Plugin;
import Tools.Logging;

constant name = "digest delivery support";
constant description = "support for digest delivery";

int _enabled = 1;
int checked_exists = 0;

mapping query_event_callers()
{
  return ([ "postDelivery" : check_digest_ready ]);
}

/*
mapping query_destination_callers()
{
  return ([ ]);
}
*/

void start()
{
  call_out(schedule_process_digests, 5);
}

void schedule_process_digests()
{
  // TODO: make sure we only have one running at a time!
  mixed e = catch(process_digests());  
  if(e) Log.exception("An exception occurred while processing digests.\n", e);
  call_out(schedule_process_digests, 3600*24);
}

// check to see if we have 20 emails ready to send; our default max digest 
// size. triggered after each email, so we can be sure that the digest
// for any list won't grow too big.
int check_digest_ready(string eventname, mapping event)
{  
  int targetsize = event->list["_options"]["digest_size"] || 20;
  object items = Fins.Model.find.archived_messages((["List": event->list, "digested": 0]));
  mixed e;
  if(items && sizeof(items) < targetsize) 
    return SpeedyDelivery.ok;

  e = catch(process_digest(event->list));

  if(e) Log.exception("An error occurred while digesting list " + event->list["name"] + ".\n", e);
  return SpeedyDelivery.ok;
}

void process_digests()
{
  foreach(Fins.Model.find.lists_all();; SpeedyDelivery.Objects.List l)
  {
    // only process digests for those lists who haven't had a digest in 
    // the last day.
    int q = l["_options"]["last_digested"];
    if(!q || (time()-q) > (3600*24))
      process_digest(l);
  }
}

// generate a mime digest for list l, marking any items as digested
// saves the time of the digesting for digest spacing purposes.
void process_digest(SpeedyDelivery.Objects.List l)
{
  Log.info("Generating Digest for " + l["name"]);
  object items = Fins.Model.find.archived_messages((["List": l, "digested": 0]));
  l["_options"]["last_digested"] = time();
  if(!sizeof(items)) 
    return;
  string subject = "Digest for " + l["name"];
  array it = map(items["content"], MIME.Message);

  foreach(it;int q; object m)
  {     
    m->headers["content-disposition"]="attachment";
    m->setdisp_param("filename", m->headers["subject"]);
    it[q] = MIME.Message((string)m, (["content-type": "message/rfc822"]));
  }

  object mime = MIME.Message("Your digest!", 
         (["content-type": "multipart/mixed", "subject": subject]), 
              ({MIME.Message("Your digest!", ([]))}) + it);
  items["digested"] = 1; 
//werror("MIME: %O\n", (string)mime);
  app->send_message_for_list(
         l, Fins.Model.find.subscriptions((["List": l, "mode": 
                      "D"]))["Subscriber"]["email"], (string)mime);    

}
