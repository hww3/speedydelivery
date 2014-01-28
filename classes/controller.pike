
inherit Fins.DocController;
inherit Fins.RootController;

Fins.FinsController auth;

Fins.FinsController newlist;
Fins.FinsController listinfo;
Fins.FinsController listadmin;
Fins.FinsController commands;
Fins.FinsController account;
Fins.FinsController mylists;
Fins.FinsController archive;
Fins.FinsController about;
Fins.FinsController rpc;

// used only for installing
Fins.FinsController install;

protected void create(object application)
{
  ::create(application);
}

void start()
{
  if(!config["application"] || !(int)config["application"]["installed"])
  {
    Tools.Logging.Log.info("Starting in install mode.");
    install = load_controller("install_controller");
//    view->default_template = Fins.Template.Simple;
    _index = install_index;
  }
  else if(config["web"] && config["web"]["noui"])
  {
    _index = noui_index;
  }
  else
  {
    auth = load_controller("auth/controller");

    listinfo = load_controller("list_controller");
    newlist = load_controller("newlist_controller");
    listadmin = load_controller("admin_controller");
    commands = load_controller("command_controller");
    account = load_controller("account_controller");
    mylists = load_controller("mylists_controller");
    archive = load_controller("archive_controller");
    about = load_controller("about_controller");

    around_filter(app->user_filter);
    _index = real_index;
  }
  
  rpc = load_controller("rpc");
}

function(object,object,object,mixed...:void) _index;

void index(mixed ... args)
{
	_index(@args);
}

void noui_index(object id, object response, object view, mixed ... args)
{
  response->set_data("");
}

void real_index(object id, object response, object view, mixed ... args)
{
  view->add("index", 1);
  view->add("lists", Fins.DataSource._default.find.lists(([]),
           Fins.Model.Criteria("ORDER BY name DESC")));
}

void install_index(object id, object response, object view, mixed ... args)
{
	// the next two lines are intended to quell a harmless error in the application log.
    view->add("user", id->misc->session_variables->user);
    view->add("request", id);

	response->redirect(install);
}
