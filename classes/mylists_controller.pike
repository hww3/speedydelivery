inherit Fins.DocController;

int __quiet = 1;

static void start()
{
  around_filter(app->mandatory_user_filter);
}

void index(object id, object response, object view, mixed args)
{
}
