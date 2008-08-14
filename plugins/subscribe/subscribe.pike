inherit SpeedyDelivery.Plugin;
import Tools.Logging;

constant name = "subscribe support";
constant description = "support for subscription via email";

int _enabled = 1;

mapping query_event_callers()
{
  return (["postSubscribe": after_subscribe,
           "createNewSubscriber": new_subscriber ]);
}

mapping query_destination_callers()
{
  return (["subscribe": handle_subscribe]);
}

int handle_subscribe(SpeedyDelivery.Request r)
{
  string s = r->mime->headers->subject + " " + r->mime->getdata();

  // format of the confirmation message is:
  // (space)CONFIRM(space)list-name(space)confirmcode(whitespace)
  //  where confirmcode is a 25 character hex hash.
  string ln, hc;
  if(sscanf(s, "%*s CONFIRM %s %25[0-9a-f]", ln, hc) == 3)
  {
    Log.info("have a correctly formed confirmation response.");
    if(ln == r->list["name"])
    return confirm_subscription(r, ln, hc);
  }

  array sa = replace(lower_case(s), 
                    ({"\r", "\n", "\t", ".", ",", "!", "?"}), 
                    ({" ", " ", " ", " ", " ", " ", " "}))/" ";

  if(search(sa, "subscribe") == -1) // we don't have the magic word!
  {
    Log.info("sending help to wandering subscriber.");
    return app->generate_help(r);
  }

  SpeedyDelivery.Objects.Subscriber subscriber;

  catch(subscriber = 
        Fins.Model.find.subscribers_by_alt(r->sender->get_address()));
  
  if(subscriber && r->list->get_subscription(subscriber))
  {
    Log.info("sending notice of duplicate subscription attempt.");
    return generate_duplicate_subscription(r);
  }


  return generate_confirmation(r);
}

int new_subscriber(string eventname, mapping event, mixed ... args)
{
    object mime = MIME.Message();
    mime->headers["subject"] = "Welcome to SpeedyDelivery!";
    mime->headers["to"] = event->subscriber->get_address();
    mime->headers["from"] = app->get_listmaster_address();

// TODO: we should use standard Fins templates rather than
// our own crazy substitution system.
  
    string msg = 
#string "new_user.txt";

    mapping vals = ([]);
    mapping m = (mapping)event->subscriber;
    foreach(m; mixed k; mixed v)
     if(stringp(v))
      vals["#user." + k + "#"] = (string)v;

    msg = replace(msg, indices(vals), values(vals));

    mime->setdata(msg);
Log.info("sending welcome subscriber email to %s.",
event->subscriber->get_address());

    app->send_message( app->get_listmaster_address(), ({event->subscriber->get_address()}), (string)mime);
}

int generate_confirmation(SpeedyDelivery.Request r)
{
  SpeedyDelivery.Objects.Confirmation c;

  Log.info("generating confirmation for %s\n", r->list["name"]);

  c = SpeedyDelivery.Objects.Confirmation();
  c->new_from_request(r);

  object mime = MIME.Message();
  mime->headers["subject"] = "Confirm Subscription to " + r->list["name"];
  mime->headers["to"] = r->sender->get_address();
  mime->headers["from"] = app->get_address_for_function(r->list, "subscribe");

  string msg = r->list["_options"]["confirm_message"] ||
#string "confirm.txt";

  mapping vals = ([]);
  mapping m = (mapping)r->list;
  foreach(m; mixed k; mixed v)
   if(stringp(v))
     vals["#list." + k + "#"] = (string)v;

  m = (mapping)c;
  foreach(m; mixed k; mixed v)
   if(stringp(v))
     vals["#confirmation." + k + "#"] = (string)v;

  msg = replace(msg, indices(vals), values(vals));

  mime->setdata(msg);
  app->send_message_for_list(r->list, ({r->sender->get_address()}), (string)mime);

  return 250;
}

int generate_duplicate_subscription(SpeedyDelivery.Request r)
{
  return 250;
}

int after_subscribe(string eventname, mapping event, mixed ... args)
{
  if(!event->quiet)
  {
    object mime = MIME.Message();
    mime->headers["subject"] = "Welcome to " + event->list["name"];
    mime->headers["to"] = event->subscriber->get_address();
    mime->headers["from"] = app->get_bounce_address(event->list);

// TODO: we should use standard Fins templates rather than
// our own crazy substitution system.
  
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

int confirm_subscription(SpeedyDelivery.Request r, string ln, string hc)
{
  Log.info("handling confirmation id %s for list %s.", hc, ln);
  if(r->list["name"] != ln) return 0;

  SpeedyDelivery.Objects.Confirmation c;
  catch( c = Fins.Model.find.confirmations_by_alt(hc));

  if(!c) return 1;
  if(c["conftype"] != r->functionname) return 0;
  if(c["list"] != r->list["name"]) return 0;

  else
  {
    r->list->subscribe(c);
    return 0;
  } 
}

