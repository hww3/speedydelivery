inherit Fins.DocController;

static void start()
{
  before_filter(app->admin_user_filter);
}



void index(object id, object response, object view, mixed args)
{
  view->add("list", Fins.Model.find.lists_by_alt(args[0]));
}
