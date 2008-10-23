inherit Fins.DocController;

static void start()
{
  around_filter(app->mandatory_user_filter);
}

void index(object id, object response, object view, mixed args)
{
  object user = id->misc->session_variables->user;
}
