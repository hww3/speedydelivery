// auto-generated by Fins.AdminTools.ModelBuilder.

import SpeedyDelivery.Objects;
inherit Fins.Model.DirectAccessInstance;

object repository = Fins.Model;
string type_name = "List";

Subscription get_subscription(Subscriber s)
{
  mixed sa = Fins.Model.find.subscriptions(
       (["Subscriber": s, "List": this]));

  if(sa && sizeof(sa)) return sa[0];
}

Subscription subscribe(Confirmation|Subscriber|Mail.MailAddress s)
{
  if(object_program(s) == Confirmation)
  {
    if(s["list"] == this["name"])
    {
      object rx = subscribe_via_mailaddress(Mail.MailAddress(s["email"]));
      s->delete();
    }
  }
  else if(object_program(s) == Mail.MailAddress)
  {
    return subscribe_via_mailaddress(s);
  }
  else // we have a subscriber object
  {
    return s->subscribe(this, this["_options"]["quiet_subscribe"]);
  }
}


Subscription unsubscribe(Confirmation|Subscriber|Mail.MailAddress s)
{
  if(object_program(s) == Confirmation)
  {
    if(s["list"] == this["name"])
    {
      object rx = unsubscribe_via_mailaddress(Mail.MailAddress(s["email"]));
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

Subscription subscribe_via_mailaddress(Mail.MailAddress m)
{
  Subscriber sx;
  catch(sx = Fins.Model.find.subscribers_by_alt(m->get_address()));   
  if(!sx) 
  {
    sx = Subscriber();
    sx->new_from_address(m);
  }
  return sx->subscribe(this, this["_options"]["quiet_subscribe"]);
}


Subscription unsubscribe_via_mailaddress(Mail.MailAddress m)
{
  Subscriber sx;
  catch(sx = Fins.Model.find.subscribers_by_alt(m->get_address()));   
  if(!sx) 
  {
    return 0;
  }
  return sx->unsubscribe(this, this["_options"]["quiet_unsubscribe"]);
}


