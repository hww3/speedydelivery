// auto-generated by Fins.AdminTools.ModelBuilder.

import SpeedyDelivery.Objects;

inherit Fins.Model.DirectAccessInstance;
object repository = Fins.Model;
string type_name = "Subscriber";

Mail.MailAddress get_address()
{
  return this["email"];
}

Subscription get_subscription(List list)
{
  mixed sa = Fins.Model.find.subscriptions(
       (["Subscriber": this, "List": list]));

  if(sa && sizeof(sa)) return sa[0];
}

Subscription subscribe(List list, int|void quiet)
{
  object s;

  s = get_subscription(list);

  if(s) throw(Error.Generic("Already subscribed to this list\n"));

  if(master_object->context->app->trigger_event("preSubscribe", 
             (["list": list, "subscriber": this, "quiet": quiet]))  
    == SpeedyDelivery.abort) return 0;

  s = Subscription();
  s["Subscriber"] = this;
  s["List"] = list;
  s->save();

  if(master_object->context->app->trigger_event("postSubscribe", 
             (["list": list, "subscriber": this, "quiet": quiet]))  
    == SpeedyDelivery.abort) return s;

  return s;
}

int unsubscribe(List list, int|void quiet)
{
  object s;

  s = get_subscription(list);

  if(!s) throw(Error.Generic("Not subscribed to this list\n"));

  if(master_object->context->app->trigger_event("preUnsubscribe", 
             (["list": list, "subscriber": this, "quiet": quiet]))
    == SpeedyDelivery.abort) return SpeedyDelivery.abort;


  s->delete();

  return master_object->context->app->trigger_event("postUnsubscribe", 
             (["list": list, "subscriber": this, "quiet": quiet]));  

}


void new_from_address(Mail.MailAddress s)
{
  string name = s->name||s->localpart;
  string address = s->get_address();

  if(name)
    this["name"] = name;  
  this["email"] = address;

  this["password"] = gen_password();
  save();

  master_object->context->app->trigger_event("createNewSubscriber", 
             (["subscriber": this]));
}

string gen_password()
{
  string q = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  string xx = "";

  for(int x = 0; x < 10; x++)
  {
    int qq = random(25);
    xx += q[qq..qq];
  }

  return xx;
}
