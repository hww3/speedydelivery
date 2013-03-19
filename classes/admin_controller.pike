inherit Fins.DocController;

int __quiet=1;

#define CHECKADMIN()  object user = id->misc->session_variables->user;  object list = \
 Fins.DataSource._default.find.lists_by_alt(args[0]); \
 view->add("list", list);  if(!app->is_list_owner(list, id->misc->session_variables->user)) \
{response->set_data("You must be an owner of a list in order to access this function."); return;  }

#define CHECKADMIN_NOVIEW()  object user = id->misc->session_variables->user; \
object list = Fins.DataSource._default.find.lists_by_alt(args[0]); \
 if(!app->is_list_owner(list, id->misc->session_variables->user)) \
 {response->set_data("You must be an owner of a list in order to access this function."); return;  }

static void start()
{
  around_filter(app->mandatory_user_filter);
}

void display(object id, object response, object view, mixed ... args)
{
  CHECKADMIN();
}

void displayholds(object id, object response, object view, mixed ... args)
{
  CHECKADMIN();
  view->add("holds", 
    Fins.DataSource._default.find.held_messages((["List": list])) 
  );
}

void displaysettings(object id, object response, object view, mixed ... args)
{
  CHECKADMIN();
}

void displayhold(object id, object response, object view, mixed ... args)
{
  CHECKADMIN();
  int sid = (int)(id->variables->id);

  if(!sid)
  {
    response->flash("No Hold ID Provided.");
    response->redirect(displayholds, list);
    return;
  }

  view->add("hold", 
    Fins.DataSource._default.find.held_messages_by_id(sid) 
  );
}

void displaysubscriptions(object id, object response, object view, mixed ... args)
{
  CHECKADMIN();
}

void listusers(object id, object response, object view, mixed ... args)
{
  CHECKADMIN_NOVIEW();
  String.Buffer d = String.Buffer();
 
  foreach(list["Subscriptions"]["Subscriber"];; object s)
    d += ("\"" + s["name"] + "\" <" + s["email"] + ">\n");

  response->set_data(d);
  response->set_type("text/plain");
}

void updatemode(object id, object response, object view, mixed ... args)
{
  CHECKADMIN_NOVIEW();
  int sid = (int)(id->variables->id);
  response->redirect(displaysubscriptions, args);

  if(!sid)
  {
    response->flash("No Subscription ID provided");    
    return;
  }

  object s = Fins.DataSource._default.find.subscriptions_by_id(sid);

  if(s["List"] != list)
  {
    response->flash("Invalid Subscription provided");
  }
  else
  {
    if(id->variables->mode == "U")
    {
      list->unsubscribe(s["Subscriber"]);
      response->flash("User unsubscribed.");  
    }
    else
    {
      s["mode"] = id->variables->mode;
      response->flash("Subscription updated.");  
    }
  }

  return;
}

void bulksubscribe(object id, object response, object view, mixed ... args)
{
  CHECKADMIN_NOVIEW();
  int i;
  array fl = ({});

  response->redirect(displaysubscriptions, args);

  id->variables->addresses-=("\r");
  array addresses = (id->variables->addresses/"\n" - ({""}));

  foreach(addresses;; string address)
  {
    object a;
    mixed e = catch(a = Mail.MailAddress(address));
    if(!a)
    { 
      fl  += ({ address });
    }
    else
    {
      e = catch(list->subscribe(a));
      if(e) fl+= ({a->get_address() + " (" + e->message() + ")" });
      else i++;
    }
  }

  string fails = "";

  if(sizeof(fl))
  {
    fails+="The following addresses are invalid and were not subscribed: ";
    foreach(fl;;string address)
      fails += (address  + "<br>\n");
  }
  response->flash(i + " addresses subscribed successfully. " + fails);
}

void processhold(object id, object response, object view, mixed ... args)
{
  CHECKADMIN_NOVIEW();
  int sid = (int)(id->variables->id);
  response->redirect(displayholds, args);

  if(!sid)
  {
    response->flash("No Hold ID provided");    
    return;
  }

  object s = Fins.DataSource._default.find.held_messages_by_id(sid);

  if(s["List"] != list)
  {
    response->flash("Invalid Hold provided");
  }
  else
  {
    if(id->variables->action == "reject")
    {
      response->flash("Hold processed successfully.");
      s->delete();
    }
    else if(id->variables->action == "release")
    {
      response->flash("Hold processed successfully.");
      s->release();
    }
    else if(id->variables->action == "edit")
    {
      response->flash("Hold processed successfully.");
    }

  }
}
