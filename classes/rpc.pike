inherit Fins.XMLRPCController;

//! @param campaign_id
//!  optional identifier for campaign, must be unique. if not provided, a unique uuid will be used.
//!
//! @param owner_email
//!   email address of "owner" of the campaign. will automatically be added as a subscriber to the campaign.
//!
//! @param options
//!    list of options for controlling the campaign.
//!       valid options are:
//!
//!        title
//!        description
//! @param subscribers
//!   array containing a list of subscribers and subscriber data.
//!   required fields include:
//!        name
//!        address (email)
string create_campaign(object request, string|void campaign_id, string owner_email, mapping options, 
  array(mapping) subscribers)
{ 
  mixed err = catch{
    
  object l = SpeedyDelivery.new_list(0, owner_email, options->description, options->title);
  object addr = Mail.MailAddress(owner_email);
  
  foreach(subscribers;; mapping subscriber)
  {
    object s = SpeedyDelivery.failsafe_get_subscriber_object(Mail.MailAddress(subscriber["address"]));
    s["name"] = subscriber["name"];
    s->subscribe(l, 1 /* quiet! */);
    s["_options"]->data = subscriber;
  }
  
  return l["name"];
  };
  
  if(err) werror("error: %s\n", master()->describe_backtrace(err));
  
  return 0;
  
}

//! @param sender
//!   a valid rfc compliant email address.
//! @param template
//!   a valid MIME formatted message
int send_message(object request, string campaign_id, string sender, string template, mapping options)
{  
  
  mixed err = catch{
    object m = MIME.Message(template);
    m->headers->from = sender;
    return send_message_as_mime(campaign_id, sender, m, options);
  };
  
  if(err) werror("error: %s\n", master()->describe_backtrace(err));
  return 1;
}

static int send_message_as_mime(string campaign_id, string sender, object mime, mapping options)
{
  object rq = SpeedyDelivery.Request(app, mime, sender, campaign_id + "@" + app->getmyhostname());
  app->distribute_message(rq);
  return 1;
}

mixed campaign_status(object request, string campaign_id)
{
  object list = app->ds->find->lists_by_alt(campaign_id);
//  Fins.Model.get_context("_default")->find->subscriptions((["List": request->list, 
//  "mode": "M"]))[*]["Subscriber"][*]["email"]
  mixed subs = (list["Subscriptions"]["Subscriber"]);
  array x = allocate(sizeof(subs));
  foreach(subs;int i;mixed sub)
    x[i] = (["email": sub["email"], "bounces": sub["bounces"]]);  
  return x;
}
