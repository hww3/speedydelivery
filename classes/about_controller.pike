
inherit Fins.DocController;

void start()
{
    around_filter(app->user_filter);
}

void index(mixed ... args)
{
}
