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

string getfullbodytext(object mime, string|void s)
{
  if(!s) s = "";

  s = mime->getdata();

  if(mime->body_parts)
  {
    foreach(mime->body_parts;; object nm)
      s = getfullbodytext(nm, s);
  }

  return s;
}

int handle_unsubscribe(SpeedyDelivery.Request r)
{
  string s = r->mime->headers->subject + " " + getfullbodytext(r->mime);

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

  if(search(lower_case(Tools.String.textify(s)), "unsubscribe") == -1) // we don't have the magic word!
  {
    Log.info("sending help to wandering unsubscriber.");
    return app->generate_help(r);
  }

  return r->list->request_unsubscription(r->sender);
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

//    vals["#list.posting_address#"] = app->get_address_for_function(event->list, 0);
//    vals["#list.unsubscribe_address#"] = app->get_address_for_function(event->list, "unsubscribe");


    object v = app->view->get_string_view(msg);

    v->add("list", event->list);
    v->add("subscriber", event->subscriber);

    mime->setdata(v->render());
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

