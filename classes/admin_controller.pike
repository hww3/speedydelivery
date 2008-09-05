inherit Fins.DocController;

static void start()
{
  around_filter(app->mandatory_user_filter);
}

void index(object id, object response, object view, mixed args)
{
  object user = id->misc->session_variables->user;
  object list = Fins.Model.find.lists_by_alt(args[0]);
  view->add("list", list);
  if(!app->is_list_owner(list, id->misc->session_variables->user))
  {
    response->set_data("You must be an owner of a list in order to access its administration settings.");
    return;
  }

}
