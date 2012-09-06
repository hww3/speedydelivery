inherit Fins.DocController;

static void start()
{
  around_filter(app->user_filter);
}

void index(object id, object response, object view, mixed ln)
{
  object list = Fins.DataSource._default.find.lists_by_alt(ln);
  view->add("list", list);

  object user = id->misc->session_variables->user;
  object s; // the subscription, if we have it.

  if(user && (s = list->get_subscription(user)))
    view->add("subscription", s);
}
