
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
//!        
string create_campaign(string|void campaign_id, string owner_email, mapping options, 
  array(mapping) subscribers)
{ 
  object l = SpeedyDelivery.new_list(0, owner_email, options->description, options->title);
  object addr = Mail.MailAddress(owner_address);
  
  object s = failsafe_get_subscriber_object(addr);
  s->subscribe(l, 1 /* quiet! */);
  
  foreach(subscribers;; mapping subscriber)
  {
    
  }
  
  return l["name"];
}

int send_message(string campaign_id, string template, mapping options)
{
  return 1;
}

mapping campaign_status(string campaign_id)
{
  return ([]);
}
