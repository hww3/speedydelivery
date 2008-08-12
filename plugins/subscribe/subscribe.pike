inherit SpeedyDelivery.Plugin;

constant name = "subscribe support";
constant description = "support for subscription via email";

int _enabled = 1;

mapping query_event_callers()
{
  return (["postSubscribe": after_subscribe]);
}

mapping query_destination_callers()
{
  return (["subscribe": handle_subscribe]);
}

int handle_subscribe(SpeedyDelivery.Request r)
{

}

int after_subscribe(string eventname, mapping event, mixed ... args)
{
  if(!event->quiet)
  {
    object mime = MIME.Message();
    mime->headers["subject"] = "Welcome to " + event->list["name"];
    mime->headers["to"] = event->subscriber->get_address();
    mime->headers["from"] = app->get_bounce_address(event->list);
  
    string msg =        event->list["_options"]["welcome_message"] ||
#string "welcome.txt";

    mapping vals = ([]);
    mapping m = (mapping)event->list;
    foreach(m; mixed k; mixed v)
     if(stringp(v))
      vals["#list." + k + "#"] = (string)v;
    m = (mapping)event->subscriber;
    foreach(m; mixed k; mixed v)
     if(stringp(v))
      vals["#subscriber." + k + "#"] = (string)v;

    vals["#list.posting_address#"] = app->get_address_for_function(event->list, 0);
    vals["#list.unsubscribe_address#"] = app->get_address_for_function(event->list, "unsubscribe");

    msg = replace(msg, indices(vals), values(vals));

    mime->setdata(msg);
    app->send_message_for_list(event->list, ({event->subscriber->get_address()}), (string)mime);
  }
}
