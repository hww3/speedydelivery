inherit SpeedyDelivery.Plugin;
import Tools.Logging;

constant name = "unsubscribe support";
constant description = "support for unsubscription via email";

int _enabled = 1;

mapping query_event_callers()
{
  return (["postUnsubscribe": after_unsubscribe,
          ]);
}

mapping query_destination_callers()
{
  return (["unsubscribe": handle_unsubscribe]);
}

int handle_unsubscribe(SpeedyDelivery.Request r)
{
  string s = " " + r->mime->headers->subject + " " + r->mime->getdata();

  // format of the confirmation message is:
  // (space)CONFIRM(space)list-name(space)confirmcode(whitespace)
  //  where confirmcode is a 25 character hex hash.
  string ln, hc;
  if(sscanf(s, "%*s CONFIRM %s %25[0-9a-f]", ln, hc) == 3)
  {
    Log.info("have a correctly formed confirmation response.");
    if(ln == r->list["name"])
    return confirm_unsubscription(r, ln, hc);
  }

  if(search(lower_case(s), "unsubscribe") == -1) // we don't have the magic word!
  {
    Log.info("sending help to wandering unsubscriber.");
    return app->generate_help(r);
  }

  SpeedyDelivery.Objects.Subscriber subscriber;

  catch(subscriber = 
        Fins.Model.find.subscribers_by_alt(r->sender->get_address()));
  
  if(!subscriber || !r->list->get_subscription(subscriber))
  {
    Log.info("sending notice of invalid unsubscription attempt.");
    return generate_invalid_unsubscription(r);
  }


  return generate_confirmation(r);
}

int generate_confirmation(SpeedyDelivery.Request r)
{
  SpeedyDelivery.Objects.Confirmation c;

  Log.info("generating confirmation for %s\n", r->list["name"]);

  c = SpeedyDelivery.Objects.Confirmation();
  c->new_from_request(r);

  object mime = MIME.Message();
  mime->headers["subject"] = "Confirm Unsubscription to " + r->list["name"];
  mime->headers["to"] = r->sender->get_address();
  mime->headers["from"] = app->get_address_for_function(r->list, "unsubscribe");

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

// TODO: complete this code.
int generate_invalid_unsubscription(SpeedyDelivery.Request r)
{
  return 250;
}

int after_unsubscribe(string eventname, mapping event, mixed ... args)
{
  if(!event->quiet)
  {
    object mime = MIME.Message();
    mime->headers["subject"] = "Successful Unsubscription from " + event->list["name"];
    mime->headers["to"] = event->subscriber->get_address();
    mime->headers["from"] = app->get_bounce_address(event->list);

// TODO: we should use standard Fins templates rather than
// our own crazy substitution system.
  
    string msg =        event->list["_options"]["goodbye_message"] ||
#string "goodbye.txt";

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

int confirm_unsubscription(SpeedyDelivery.Request r, string ln, string hc)
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
    r->list->unsubscribe(c);
    return 0;
  } 
}

