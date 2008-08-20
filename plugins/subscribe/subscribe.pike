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

  return r->list->request_subscription(r->sender->get_address());

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

  object v = app->view->get_string_view(msg);

  v->add("user", event->subscriber);

  mime->setdata(v->render());

  Log.info("sending welcome subscriber email to %s.",
  event->subscriber->get_address());

  app->send_message( app->get_listmaster_address(), ({event->subscriber->get_address()}), (string)mime);
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

    object v = app->view->get_string_view(msg);

    v->add("list", event->list);
    v->add("subscriber", event->subscriber);

    mime->setdata(v->render());

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

