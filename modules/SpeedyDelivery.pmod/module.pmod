//!
constant abort = 1;

//!
constant ok = 0;

//!
constant STRING = 1;

//!
constant BOOLEAN = 2;

//!
constant INTEGER = 4;


//! gets all of the parts of the message that are of type text/*
string getfullbodytext(object mime, string|void s)
{
  if(!s) s = "";
  if(!mime->headers["content-type"] || has_prefix(lower_case((string)mime->headers["content-type"]), "text/"))
    s += mime->getdata();

  if(mime->body_parts)
  {
    foreach(mime->body_parts;; object nm)
      s += getfullbodytext(nm);
  }

  return s;
}

//! gets all of the parts of the message that are of type mt, defaults
//! to text/plain.
string getfullbodymimetext(object mime, string|void mt, string|void s)
{
  if(!mt) mt = "text/plain";
  if(!s) s = "";
  if(has_prefix(lower_case(mime->headers["content-type"]||"text/plain"), mt) || (!mime->headers["content-type"] && mt=="text/plain"))
  {
    s += mime->getdata();
  }
  if(mime->body_parts)
  {
    foreach(mime->body_parts;; object nm)
    {
      s += getfullbodymimetext(nm, mt);
    }    
  }

  return s;
}


//!
object new_list(string name, string owner_address, string description, string title, string|void return_host)
{
  
  object l, s;

  if(!name) name = (string)Standards.UUID.make_version1(time());

  // check to see if the list name is in use.
  catch(l = Fins.Model.get_context("_default")->find->lists_by_alt(name));

  if(l)
    throw(Error.Generic("List name '" + name + "' is already in use."));

  //check to see if the email address is valid.
  object addr = Mail.MailAddress(owner_address);

  if(!addr)
    throw(Error.Generic("Email address '" + owner_address + "' is invalid."));

  l = SpeedyDelivery.Objects.List();
  l["name"] = name;

  s = failsafe_get_subscriber_object(addr);

  l["description"] = description;
  l["title"] = title;
  if(return_host && strlen(return_host))
    l["return_host"] = return_host;
  l->save();

  // we can't do this until we are saved. probably a fixme in fins.
  l["list_owners"] += s;
  
  return l;
}

//! may return null if subscriber email is not recognized.
object get_subscriber_object(object addr)
{
  object s;
  // prepare the list owner.
  catch(s = Fins.Model.get_context("_default")->find->subscribers_by_alt(addr->get_address()));

  return s;
}

object failsafe_get_subscriber_object(object addr)
{
  object s;
  // prepare the list owner.
  catch(s = Fins.Model.get_context("_default")->find->subscribers_by_alt(addr->get_address()));

  if(!s) 
  {
    s = SpeedyDelivery.Objects.Subscriber();
    s->new_from_address(addr);
  }  
  
  return s;
}
