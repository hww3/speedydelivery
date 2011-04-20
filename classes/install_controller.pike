//<locale-token project="SpeedyDelivery">LOCALE</locale-token>

#define LOCALE(X,Y) Locale.translate(app->config->app_name, id->get_lang(), X, Y)

import Fins;
import Tools.Logging;
inherit Fins.FinsController;

public void index(Request id, Response response, mixed ... args)
{
  object v = view->get_view("install/index");
//  v->add("dbs", available_dbs());
  response->set_view(v);
}

public void do_setup(Request id, Response response, mixed ... args)
{
  response->redirect(complete);
}

public void complete(Request id, Response response, mixed ... args)
{
  object v = view->get_view("install/complete");
//  v->add("dbs", available_dbs());
  response->set_view(v);
  app->controller->install = 0;
  app->reload_controllers();
}

