inherit Fins.DocController;
int __quiet = 1;

void subscribe(object id, object response, object view, mixed args)
{
  object list = Fins.Model.find.lists_by_alt(args[0]);
  int r = list->request_subscription(id->variables->email, id->variables->name);

  if(r == 260)
    response->flash("You are already subscribed to " + list["name"] + ".");
  if(r == 250)
    response->flash("A confirmation request has been sent to  to " + id->variables->email + ".");
  response->redirect(app->controller->listinfo, args);
}

void unsubscribe(object id, object response, object view, mixed args)
{
  object list = Fins.Model.find.lists_by_alt(args[0]);
  int r = list->request_unsubscription(id->variables->email);
werror("response: %O\n", r);
  if(r == 260)
    response->flash("You are not subscribed to " + list["name"] + ".");
  if(r == 250)
    response->flash("A confirmation request has been sent to  to " + id->variables->email + ".");
  response->redirect(app->controller->listinfo, args);
}

