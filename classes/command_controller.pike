inherit Fins.DocController;
int __quiet = 1;

void subscribe(object id, object response, object view, mixed args)
{
  object list = Fins.DataSource._default.find.lists_by_alt(args[0]);
  int r = list->request_subscription(id->variables->email, id->variables->name, (int)id->variables->digest);

  if(r == 260)
    response->flash("You are already subscribed to " + list["name"] + ".");
  if(r == 250)
    response->flash("A confirmation request has been sent to  to " + id->variables->email + ".");
  response->redirect(app->controller->listinfo, args);
}

void unsubscribe(object id, object response, object view, mixed args)
{
  object list = Fins.DataSource._default.find.lists_by_alt(args[0]);
  int r = list->request_unsubscription(id->variables->email);
werror("response: %O\n", r);
  if(r == 260)
    response->flash("You are not subscribed to " + list["name"] + ".");
  if(r == 250)
    response->flash("A confirmation request has been sent to  to " + id->variables->email + ".");
  response->redirect(app->controller->listinfo, args);
}

void setmode(object id, object response, object view, mixed args)
{
  object list = Fins.DataSource._default.find.lists_by_alt(args[0]);
  object s;

  if(!id->misc->session_variables->user)
    response->flash("You must be logged in to change your deliver mode.");
  else if(!(s = list->get_subscription(id->misc->session_variables->user)))
    response->flash("You must be subscribed to this list in order to change delivery settings.");
  else if(!(<"M", "D", "S">)[id->variables->mode])
    response->flash("You have selected an invalid option.");
  else
  {
   s["mode"] = id->variables->mode;
    response->flash("Your delivery mode has been changed.");
  }

  response->redirect(app->controller->listinfo, args);
}
