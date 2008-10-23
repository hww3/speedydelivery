// auto-generated by Fins.AdminTools.ModelBuilder.

import SpeedyDelivery.Objects;
import Tools.Logging;
inherit Fins.Model.DirectAccessInstance;

object repository = Fins.Model;
string type_name = "List";

int is_owner(SpeedyDelivery.Objects.Subscriber user)
{
  return has_value(this["list_owners"], user);
}


Subscription get_subscription(Subscriber s)
{
  mixed sa = Fins.Model.find.subscriptions(
       (["Subscriber": s, "List": this]));

  if(sa && sizeof(sa)) 
    return sa[0];
  else 
    return 0;
}

int request_unsubscription(string|Mail.MailAddress email)
{
  Mail.MailAddress a;
  if(stringp(email))
    a = Mail.MailAddress("<" + email + ">");
  else
    a = email;

  SpeedyDelivery.Objects.Subscriber subscriber;

  catch(subscriber =
        Fins.Model.find.subscribers_by_alt(a->get_address()));

  if(!subscriber || !get_subscription(subscriber))
  {
    Log.info("sending notice of invalid unsubscription attempt.");
    return generate_invalid_unsubscription(a);
  }

  return generate_unsubscription_confirmation(a);

}

int request_subscription(string|Mail.MailAddress email, string|void name, int|void digest)
{
  Mail.MailAddress a;
  if(stringp(email))
    a = Mail.MailAddress("\"" + (name||"") + "\" <" + email + ">");
  else
    a = email;

  object subscriber;

  catch(subscriber =
        Fins.Model.find.subscribers_by_alt(a->get_address()));

  if(subscriber && get_subscription(subscriber))
  {
    Log.info("sending notice of duplicate subscription attempt.");
    return generate_duplicate_subscription(a);
  }

  return generate_subscription_confirmation(a, digest);
}

Subscription subscribe(Confirmation|Subscriber|Mail.MailAddress s, int|void digest)
{
  if(object_program(s) == Confirmation)
  {
    if(s["list"] == this["name"])
    {
      object rx = subscribe_via_mailaddress(Mail.MailAddress(s["email"]), s["_options"]["digest"]);
      s->delete();
    }
  }
  else if(object_program(s) == Mail.MailAddress)
  {
    return subscribe_via_mailaddress(s, digest);
  }
  else // we have a subscriber object
  {
    return s->subscribe(this, this["_options"]["quiet_subscribe"], digest);
  }
}


int unsubscribe(Confirmation|Subscriber|Mail.MailAddress s)
{
  if(object_program(s) == Confirmation)
  {
    if(s["list"] == this["name"])
    {
      unsubscribe_via_mailaddress(Mail.MailAddress(s["email"]));
      s->delete();
    }
  }
  else if(object_program(s) == Mail.MailAddress)
  {
    return unsubscribe_via_mailaddress(s);
  }
  else // we have a subscriber object
  {
    return s->unsubscribe(this, this["_options"]["quiet_unsubscribe"]);
  }
}

Subscription subscribe_via_mailaddress(Mail.MailAddress m, int|void digest)
{
  Subscriber sx;
  catch(sx = Fins.Model.find.subscribers_by_alt(m->get_address()));   
  if(!sx) 
  {
    sx = Subscriber();
    sx->new_from_address(m);
  }
  object subscription = sx->subscribe(this, this["_options"]["quiet_subscribe"]);
  if(digest)
    subscription["mode"] = "D";
  return subscription;
}


int unsubscribe_via_mailaddress(Mail.MailAddress m)
{
  Subscriber sx;
  catch(sx = Fins.Model.find.subscribers_by_alt(m->get_address()));   
  if(!sx) 
  {
    return 0;
  }
  return sx->unsubscribe(this, this["_options"]["quiet_unsubscribe"]);
}

int enable_plugin(string plugin)
{
  mapping o = this["_options"];
  if(!o["enabled_plugins"]) o["enabled_plugins"] = ([]);

  o["enabled_plugins"][plugin] = 1;
}

int disable_plugin(string plugin)
{
  mapping o = this["_options"];
  if(!o["enabled_plugins"]) o["enabled_plugins"] = ([]);

  o["enabled_plugins"][plugin] = 0;
}

// triggers an event based on list permissions.
int trigger_event(string event, mixed ... args)
{
  int retval;
  Log.debug("Calling event " + event + " for list %O", this);
  if(master_object->context->app->event_handlers[event])
  {
    foreach(master_object->context->app->event_handlers[event];; function h)
    {
      object o = function_object(h);
      if(!o->list_enabled(this)) continue;

      int res = h(event, @args);

      retval|=res;

      if(res & SpeedyDelivery.abort)
         break;
    }
  }
  return retval;
}

int generate_unsubscription_confirmation(Mail.MailAddress sender)
{
  SpeedyDelivery.Objects.Confirmation c;

  Log.info("generating confirmation for %s\n", this["name"]);

  c = SpeedyDelivery.Objects.Confirmation();
  c->new(this, sender, "unsubscribe");

  object mime = MIME.Message();
  mime->headers["subject"] = "Confirm Unsubscription to " + this["name"];
  mime->headers["to"] = sender->get_address();
  mime->headers["from"] = master_object->context->app->get_address_for_function(this, "unsubscribe");

  string msg = this["_options"]["confirm_message"] ||
#string "../../../plugins/unsubscribe/confirm.txt";

  object v = master_object->context->app->view->get_string_view(msg);

  v->add("list", this);
  v->add("confirmation", c);

  mime->setdata(v->render());
  master_object->context->app->send_message_for_list(this, ({sender->get_address()}), (string)mime);

  return 250;
}


int generate_subscription_confirmation(Mail.MailAddress sender, int|void digest)
{
  SpeedyDelivery.Objects.Confirmation c;

  Log.info("generating confirmation for %s\n", this["name"]);

  c = SpeedyDelivery.Objects.Confirmation();
// void new(SpeedyDelivery.Objects.List list, Mail.MailAddress sender, string functionname)
  c->new(this, sender, "subscribe", digest);

  object mime = MIME.Message();
  mime->headers["subject"] = "Confirm Subscription to " + this["name"];
  mime->headers["to"] = sender->get_address();
  mime->headers["from"] = master_object->context->app->get_address_for_function(this, "subscribe");

  string msg = this["_options"]["confirm_message"] ||
#string "../../../plugins/subscribe/confirm.txt";

  object v = master_object->context->app->view->get_string_view(msg);

  v->add("list", this);
  v->add("confirmation", c);

  mime->setdata(v->render());
  master_object->context->app->send_message_for_list(this, ({sender->get_address()}), (string)mime);

  return 250;
}

int generate_duplicate_subscription(Mail.MailAddress a)
{
  // TODO: actually do it
  Log.info("generating duplicate subscription notice.");
  return 260;
}

int generate_invalid_unsubscription(Mail.MailAddress a)
{
  // TODO: actually do it
  Log.info("generating invalid unsubscription notice.");
  return 260;
}

int generate_duplicate_unsubscription(Mail.MailAddress a)
{
  // TODO: actually do it
  Log.info("generating duplicate unsubscription notice.");
  return 260;
}

