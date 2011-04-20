
inherit Fins.DocController;

Fins.FinsController auth;

Fins.FinsController newlist;
Fins.FinsController listinfo;
Fins.FinsController listadmin;
Fins.FinsController commands;
Fins.FinsController account;
Fins.FinsController archive;

// used only for installing
Fins.FinsController install;

void start()
{
  if(!config["application"] || !(int)config["application"]["installed"])
  {
    Tools.Logging.Log.info("Starting in install mode.");
    install = load_controller("install_controller");
//    view->default_template = Fins.Template.Simple;
    _index = install_index;
  }
  else
  {
    auth = load_controller("auth/controller");

    listinfo = load_controller("list_controller");
    newlist = load_controller("newlist_controller");
    listadmin = load_controller("admin_controller");
    commands = load_controller("command_controller");
    account = load_controller("account_controller");
    archive = load_controller("archive_controller");

    around_filter(app->user_filter);
    _index = real_index;
  }
}

function(object,object,object,mixed...:void) _index;

void index(mixed ... args)
{
	_index(@args);
}

void real_index(object id, object response, object view, mixed ... args)
{
  view->add("lists", Fins.DataSource._default.find.lists(([]),
           Fins.Model.Criteria("ORDER BY name DESC")));
}

void install_index(object id, object response, object view, mixed ... args)
{
	response->redirect(install);
}