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

public void setup_admin(Request id, Response response, mixed ... args)
{
	array x = Fins.Model.find.subscribers((["is_admin": 1]));
	if(sizeof(x)) // we have an admin user already, so skip this step.
	{
		response->redirect(setup_smtp);
	    return;
	}
	  object v = view->get_view("install/setup_admin");
	//  v->add("dbs", available_dbs());
	  response->set_view(v);

	  // the next two lines are intended to quell a harmless error in the application log.
	  v->add("user", id->misc->session_variables->user);
	  v->add("request", id);

	  v->add_all(id->variables);	
}

public void do_setup_admin(Request id, Response response, mixed ... args)
{
  // set up the admin user
  Mail.MailAddress addr;
  
  mapping rv = id->variables + ([]);
  m_delete(rv, "password");
  m_delete(rv, "password2");

  if(!id->variables->email || !sizeof(id->variables->email))
  {
    response->flash("msg", "No administrator email supplied.");
    response->redirect(setup_admin, 0, rv);	
    return;
  }
  else if(!id->variables->name || !sizeof(id->variables->name))
  {
    response->flash("msg", "No administrator's name supplied.");
    response->redirect(setup_admin, 0, rv);	
    return;
  }
  else if(!sizeof(id->variables->password))
  {
    response->flash("msg", "No password supplied.");
    response->redirect(setup_admin, 0, rv);	
    return;
  }
  else if(id->variables->password != id->variables->password2)
  {
    response->flash("msg", "Passwords supplied do not match.");
    response->redirect(setup_admin, 0, rv);	
    return;
  }
   
  mixed err;
  err = catch(addr = Mail.MailAddress(id->variables->email));
  if(!addr)
  {
    response->flash("msg", "Invalid administrator email supplied: " + err[0	]);
    response->redirect(setup_admin, 0, rv);	
    return;
  }


  object admin = SpeedyDelivery.Objects.Subscriber();
  admin["email"] = id->variables->email;
  admin["name"] = id->variables->name;
  admin["password"] = id->variables->password;
  admin["is_admin"] = 1;
  admin->save();

  // set up the connection to the mail host.
  response->redirect(setup_smtp);
}

public void do_setup_smtp(Request id, Response response, mixed ... args)
{
  mapping rv = id->variables + ([]);

  if(!strlen(id->variables->outbound_host))
  {
	 response->flash("msg", "No outbound mail server specified.");
	 response->redirect(setup_smtp, 0, rv);
	 return;
  }

  if(!strlen(id->variables->outbound_port) || !((int)id->variables->outbound_port))
  {
	 response->flash("msg", "No outbound mail server port specified.");
	 response->redirect(setup_smtp, 0, rv);
	 return;
  }

  if(!strlen(id->variables->inbound_host))
  {
	 response->flash("msg", "No inbound mail server specified.");
	 response->redirect(setup_smtp, 0, rv);
	 return;
  }

  if(!strlen(id->variables->inbound_port) || !((int)id->variables->inbound_port))
  {
	 response->flash("msg", "No inbound mail server port specified.");
	 response->redirect(setup_smtp, 0, rv);
	 return;
  }

  // set up the connection to the mail host.
  function sv = app->config->set_value;
  sv("smtp", "smtp_host", id->variables->outbound_host);
  sv("smtp", "smtp_port", id->variables->outbound_port);
  sv("smtp", "listen_host", id->variables->inbound_host);
  sv("smtp", "listen_port", id->variables->inbound_port);
  sv("processors", "class", "smtp_processor");

  response->redirect(setup_domains);
}

public void setup_smtp(Request id, Response response, mixed ... args)
{
	  object v = view->get_view("install/setup_smtp");
	  response->set_view(v);

	  // the next two lines are intended to quell a harmless error in the application log.
	  v->add("user", id->misc->session_variables->user);
	  v->add("request", id);
}

public void do_setup_domains(Request id, Response response, mixed ... args)
{
  mapping rv = id->variables + ([]);

  if(!strlen(id->variables->return_host))
  {
	 response->flash("msg", "Return mail hostname specified.");
	 response->redirect(setup_domains, 0, rv);
	 return;
  }

  if(!strlen(id->variables->listmaster))
  {
	 response->flash("msg", "Listmaster address not specified.");
	 response->redirect(setup_domains, 0, rv);
	 return;
  }

  if(!strlen(id->variables->domain))
  {
	 response->flash("msg", "No list service mail domains specified.");
	 response->redirect(setup_domains, 0, rv);
	 return;
  }

  Mail.MailAddress addr;
  mixed err;
  err = catch(addr = Mail.MailAddress(id->variables->listmaster));
  if(!addr)
  {
    response->flash("msg", "Invalid listmaster email supplied: " + err[0]);
    response->redirect(setup_domains, 0, rv);	
    return;
  }

  array domain = ({});

  foreach(id->variables->domain / "\n";;string d)
  {
    domain += ({String.trim_all_whites(d)});
  }

  // set up the connection to the mail host.
  function sv = app->config->set_value;
  sv("smtp", "domain", domain);
  sv("smtp", "listmaster", (string)addr);
  sv("smtp", "return_host", id->variables->return_host);

  response->redirect(complete);
}

public void setup_domains(Request id, Response response, mixed ... args)
{
	  object v = view->get_view("install/setup_domains");
	  response->set_view(v);

	  // the next two lines are intended to quell a harmless error in the application log.
	  v->add("user", id->misc->session_variables->user);
	  v->add("request", id);
}

public void complete(Request id, Response response, mixed ... args)
{
  object v = view->get_view("install/complete");
  response->set_view(v);

  // the next two lines are intended to quell a harmless error in the application log.
  v->add("user", id->misc->session_variables->user);
  v->add("request", id);

  app->config->set_value("application", "installed", 1);
  app->controller->install = 0;
  app->reload_controllers();
}

