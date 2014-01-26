inherit Fins.DocController;

int __quiet=1;

#define CHECKADMIN() {object user = id->misc->session_variables->user; \
 if(!app->is_list_master(id->misc->session_variables->user)) \
 {response->set_data("You must be a list master in order to access this function."); return;  }}

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
  object l;
  mixed e = catch(l = SpeedyDelivery.new_list(id->variables->name, 
       id->variables->owner_address, 
       id->variables->description, 
       id->variables->title));

  if(e)
  {
    e = Error.mkerror(e);
    response->flash(e->message());
    response->redirect(new);
    return;
  }

  foreach(l["list_owners"];; object owner)
    owner->subscribe(l);

  response->flash("List " + id->variables->name + " created successfully.");
  response->redirect(app->controller);
}

