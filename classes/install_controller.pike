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

  // the next two lines are intended to quell a harmless error in the application log.
  v->add("user", id->misc->session_variables->user);
  v->add("request", id);

  v->add_all(id->variables);
}

public void do_setup(Request id, Response response, mixed ... args)
{
  // set up the admin user
  Mail.MailAddress addr;
  
  mapping rv = id->variables + ([]);
  m_delete(rv, "password");
  m_delete(rv, "password2");

  if(!id->variables->email || !sizeof(id->variables->email))
  {
    response->flash("msg", "No administrator email supplied.");
    response->redirect(index, 0, rv);	
    return;
  }
  else if(!id->variables->name || !sizeof(id->variables->name))
  {
    response->flash("msg", "No administrator's name supplied.");
    response->redirect(index, 0, rv);	
    return;
  }
  else if(!sizeof(id->variables->password))
  {
    response->flash("msg", "No password supplied.");
    response->redirect(index, 0, rv);	
    return;
  }
  else if(id->variables->password != id->variables->password2)
  {
    response->flash("msg", "Passwords supplied do not match.");
    response->redirect(index, 0, rv);	
    return;
  }
   
  mixed err;
  err = catch(addr = Mail.MailAddress(id->variables->email));
  if(!addr)
  {
    response->flash("msg", "Invalid administrator email supplied: " + err[0	]);
    response->redirect(index, 0, rv);	
    return;
  }


  object admin = SpeedyDelivery.Objects.Subscriber();
  admin["email"] = id->variables->email;
  admin["name"] = id->variables->name;
  admin["password"] = id->variables->password;
  admin["is_admin"] = 1;
  admin->save();

  // set up the connection to the mail host.
  response->redirect(complete);
}

public void complete(Request id, Response response, mixed ... args)
{
  object v = view->get_view("install/complete");
//  v->add("dbs", available_dbs());
  response->set_view(v);

  // the next two lines are intended to quell a harmless error in the application log.
  v->add("user", id->misc->session_variables->user);
  v->add("request", id);

  app->controller->install = 0;
  app->reload_controllers();
}

