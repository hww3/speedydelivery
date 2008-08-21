inherit SpeedyDelivery.Plugin;
import Tools.Logging;

constant name = "digest delivery support";
constant description = "support for digest delivery";

int _enabled = 1;
int checked_exists = 0;

/*
mapping query_event_callers()
{
  return ([ "preDelivery" : archive_message ]);
}

mapping query_destination_callers()
{
  return ([ ]);
}
*/

void start()
{
  call_out(process_digests, 5);
}

void process_digests()
{
  foreach(Fins.Model.find.lists_all();; SpeedyDelivery.Objects.List l)
  {

    Log.info("Generating Digest for " + l["name"]);
    object items = Fins.Model.find.archived_messages((["List": l, "digested": 0]));
    werror("got  " + sizeof(items) + " for " + l["name"]);
    if(!sizeof(items)) continue;
    string subject = "Digest for " + l["name"];
    array it = map(items["content"], MIME.Message);

    foreach(it;int q; object m)
    {     
      m->headers["content-disposition"]="attachment";
      m->setdisp_param("filename", m->headers["subject"]);
      it[q] = MIME.Message((string)m, (["content-type": "message/rfc822"]));
    }

    object mime = MIME.Message("Your digest!", (["content-type": "multipart/mixed", "subject": subject]), ({MIME.Message("Your digest!", ([]))}) + it);
    items["digested"] = 1; 
//werror("MIME: %O\n", (string)mime);
    app->send_message_for_list(l, Fins.Model.find.subscriptions((["List": l, "mode": "D"]))["Subscriber"]["email"], (string)mime);    

  }
}
