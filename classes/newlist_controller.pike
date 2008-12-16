inherit Fins.DocController;

int __quiet=1;

#define CHECKADMIN() object user = id->misc->session_variables->user; if(!app->is_list_master(id->misc->session_variables->user)) {response->set_data("You must be a list master in order to access this function."); return;\  }

static void start()
{
  around_filter(app->mandatory_user_filter);
}

void index(object id, object r, object v, mixed a)
{
  r->redirect(new);
}

void new(object id, object response, object view, mixed args)
{
  CHECKADMIN();
}

void do_new(object id, object response, object view, mixed args)
{
  CHECKADMIN();

  object l, s;

  // check to see if the list name is in use.
  catch(l = Fins.Model.find.lists_by_alt(id->variables->name));

  if(l)
  { 
    response->flash("List name '" + id->variables->name + "'"
                      " is already in use.");
    response->redirect(new);
    return;
  }  

  //check to see if the email address is valid.
  object addr = Mail.MailAddress(id->variables->owner_address);

  if(!addr)
  { 
    response->flash("Email address '" + id->variables->owner_address + "'"
                      " is invalid.");
    response->redirect(new);
    return;
  }

  l = SpeedyDelivery.Objects.List();
  l["name"] = id->variables->name;

  // prepare the list owner.
  catch(s = Fins.Model.find.subscribers_by_alt(addr->get_address()));

  if(!s) 
  {
    s = SpeedyDelivery.Objects.Subscriber();
    s->new_from_address(addr);
  }  

  l["description"] = id->variables->description;
  l["title"] = id->variables->title;

  l->save();

  // we can't do this until we are saved. probably a fixme in fins.
  l["list_owners"] += s;

  s->subscribe(l);

  response->flash("List " + id->variables->name + " created successfully.");
  response->redirect(app->controller);
}

