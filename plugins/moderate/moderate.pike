inherit SpeedyDelivery.Plugin;
import Tools.Logging;

constant name = "moderation support";
constant description = "support for moderating list activity";

int _enabled = 1;
int checked_exists = 0;

mapping query_event_callers()
{
  return ([ "holdMessage" : hold_message ]);
}

mapping query_destination_callers()
{
  return ([ "moderate": handle_release ]);
}

int hold_message(string eventname, mapping event, mixed ... args)
{
  Log.info("generating hold message for %s\n", event->list["name"]);

  object mime = MIME.Message();
  mime->headers["subject"] = "Moderation request from " + event->hold["envelope_from"]  + " to " + event->list["name"];
  mime->headers["from"] = app->get_address_for_function(event->list, "moderate");
  mime->headers["to"] = app->get_owner_addresses(event->list);

  string msg = event->list["_options"]["moderate_message"] ||
#string "moderate.txt";

  object v = app->view->get_string_view(msg);

  v->add("list", event->list);
  v->add("hold", event->hold);

  mime->setdata(v->render());
  app->send_message_to_list_owner(event->list, (string)mime);

  return SpeedyDelivery.ok;
}

int handle_release(SpeedyDelivery.Request r)
{
  string s = r->mime->headers->subject + " " +
    SpeedyDelivery.getfullbodytext(r->mime);

  // format of the confirmation message is:
  // (space)CONFIRM(space)list-name(space)confirmcode(whitespace)
  //  where confirmcode is a 25 character hex hash.
  string ln, hc;
  if(sscanf(s, "%*s RELEASE %s %25[0-9a-f]", ln, hc) == 3)
  {
    Log.info("have a correctly formed release response.");
    if(ln == r->list["name"])
    return release_message(r, ln, hc);
  }
  else if(sscanf(s, "%*s REJECT %s %25[0-9a-f]", ln, hc) == 3)
  {
    Log.info("have a correctly formed reject response.");
    if(ln == r->list["name"])
    return reject_message(r, ln, hc);
  }
  return SpeedyDelivery.ok;
}

int release_message(SpeedyDelivery.Request r, string ln, string hc)
{
  Log.info("handling release id %s for list %s.", hc, ln);
  if(r->list["name"] != ln) return 0;
  Log.info("=> finding release id %s for list %s.", hc, ln);
  object x;
  catch( x = Fins.Model.find.held_messages_by_alt(hc));
  SpeedyDelivery.Objects.Held_message c;
  c = [object(SpeedyDelivery.Objects.Held_message)]x;

  if(!c) return 1;
Log.info("=> found held message.");
//  if(c["conftype"] != r->functionname) return 0;
  if(c["List"]["name"] != r->list["name"]) return 0;
  else
  {
    Log.info("=> releasing id %s for list %s.", hc, ln);
    c->release();
    return 0;
  }
}

int reject_message(SpeedyDelivery.Request r, string ln, string hc)
{
  Log.info("handling reject id %s for list %s.", hc, ln);
  if(r->list["name"] != ln) return 0;
  Log.info("=> finding reject id %s for list %s.", hc, ln);
  object x;
  catch( x = Fins.Model.find.held_messages_by_alt(hc));
  SpeedyDelivery.Objects.Held_message c;
  c = [object(SpeedyDelivery.Objects.Held_message)]x;

  if(!c) return 1;
//  if(c["conftype"] != r->functionname) return 0;
  if(c["List"]["name"] != r->list["name"]) return 0;
  else
  {
    Log.info("=> rejecting id %s for list %s.", hc, ln);
    c->delete();
    return 0;
  }
}
