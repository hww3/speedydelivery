
inherit Fins.DocController;

Fins.FinsController auth;

Fins.FinsController listinfo;
Fins.FinsController listadmin;
Fins.FinsController commands;
Fins.FinsController archive;

void start()
{
  auth = load_controller("auth/controller");

  listinfo = load_controller("list_controller");
  listadmin = load_controller("admin_controller");
  commands = load_controller("command_controller");
  archive = load_controller("archive_controller");

  around_filter(app->user_filter);
}


void index(object id, object response, object view, mixed ... args)
{
  view->add("lists", Fins.Model.find.lists(([]),
           Fins.Model.Criteria("ORDER BY name DESC")));
}

