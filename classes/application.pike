import Tools.Logging;

inherit Fins.Application;

mapping plugins = ([]);
mapping event_handlers = ([]);
mapping destination_handlers = ([]);
mapping valid_addresses = ([]);

mixed ds;

void start()
{	
  ds = master()->resolv("Fins.DataSource._default");
werror("ds: %O\n", ds);
  load_default_destination_handler();
  load_plugins();
  start_queue_processor();
}

// this is the default handler for a list (ie, the list address itself).
// we'll load it as "__default" in the destination_handlers mapping.
// this code is located in list_handler.pike.
void load_default_destination_handler()
{
  program lhp = (program)"list_handler";

  object lho = lhp(this);
  destination_handlers->__default = lho->handle_post;
}

void start_queue_processor()
{
  int s = 5 + random(120);
  Log.info("Will process queue in " + s + " seconds.");
  call_out(do_process_queue, s);
}

void do_process_queue()
{
  Log.info("Processing queue.");
  process_queue();
  Log.info("Finished processing queue.");  
  int s = 5 + (config["smtp"]->queue_interval||60)*10;
  Log.info("Will process queue in " + s + " seconds.");
  call_out(do_process_queue, s);
}

void load_plugins()
{
  string plugindir = Stdio.append_path(config->app_dir, "plugins");
  array p = get_dir(plugindir);
//	Log.info("current directory is " + getcwd());
  foreach(p||({});;string f)
  {
    if(f == "CVS") continue;
		
   Log.debug("Considering plugin " + f);
   Stdio.Stat stat = file_stat(Stdio.append_path(plugindir, f));
//        Log.info("STAT: %O %O", Stdio.append_path(plugindir, f), stat);
   if(stat && stat->isdir)
   {
//			Log.info("  is a directory based plugin.");

     object installer;
     object module;
     string pd = combine_path(plugindir, f);
			
     foreach(glob("*.pike", get_dir(pd));; string file)
     {
       program p = (program)combine_path(pd, file);
	Log.debug("Plugin Program: %O", p);
       if(Program.implements(p, SpeedyDelivery.PluginInstaller) && !installer)
         installer = p(this);
       else if(Program.implements(p, SpeedyDelivery.Plugin) && !module)
         module = p(this);	
       else continue;
       module->module_dir = pd;
               
     }
			
     if(!module || module->name =="")
        continue;
			
      if(installer && functionp(installer->install) && module->installed())
        installer->install(Filesystem.System(pd));
   
      plugins[module->name] = module;
      Log.info("Registered plugin: " + module->name);
    }
  }
	
  start_plugins();
}

void start_plugins()
{
	Log.debug("Starting plugins.");
	
	foreach(plugins;string name; object plugin)
	{
           Log.debug("Processing " + name);

           // we don't start up plugins that explicitly tell us not to.
           if(plugin->enabled && !plugin->enabled())
             continue;
           Log.debug("Starting " + name);

                if(plugin->query_preferences && functionp(plugin->query_preferences))
                {
                  foreach(plugin->query_preferences(); string p; mapping pv)
                  {
                    new_pref("plugin." + plugin->name + "." + p, pv->value, pv->type);
                  }
                }

		if(plugin->start && functionp(plugin->start))
		  plugin->start();

        if(plugin->query_event_callers && 
                        functionp(plugin->query_event_callers))
        {
           mapping a = plugin->query_event_callers();

           if(a)
              foreach(a; string m; function event)
              {
			    add_event_handler(m, event);
              }
        }

                if(plugin->query_destination_callers && 
                        functionp(plugin->query_destination_callers))
                {
                  mapping a = plugin->query_destination_callers();

                  if(a)
                    foreach(a; string m; mixed f)
                    {
   	               Log.debug("adding destination handler for " + m + ".");
                       destination_handlers[m] = f;
                    }
                }

	}

}

void add_event_handler(string event, function handler)
{
  Log.debug("adding handler for " + event + ".");
  if(!event_handlers[event])
    event_handlers[event] = ({});
  event_handlers[event] += ({ handler });
}

int trigger_event(string event, mixed ... args)
{
  int retval;
  Log.debug("Calling event " + event);
  if(event_handlers[event])
  {
    foreach(event_handlers[event];; function h)
    {
      object o = function_object(h);
      if(o->list_enableable) continue;
      int res = h(event, @args);

      retval|=res; 
 
      if(res & SpeedyDelivery.abort)
         break;
    }
  }
  return retval;
}

object get_sys_pref(string pref)
{
  object p;
  catch(p = ds->find->preferences_by_alt(pref));
  return p;
}

object new_string_pref(string pref, string value)
{
  object p;
  catch(p = get_sys_pref(pref));
  if(p) return p;
  else 
  { 
     Log.info("Creating new preference object '" + pref  + "'.");
     p = ds->new("Preference");
     p["name"] = pref;
     p["type"] = SpeedyDelivery.STRING;
     p["value"] = value;
     p["description"] = "";
     p->save();
     return p;
  }
}

object new_pref(string pref, string value, int type)
{
  object p;
  catch(p = get_sys_pref(pref));
  if(p) return p;
  else 
  { 
     p = ds->new("Preference");
     p["name"] = pref;
     p["type"] = type;
     p["description"] = "";
     p["value"] = value;
     p->save();
     return p;
  }
}

int is_list_master(SpeedyDelivery.Objects.Subscriber user)
{
  return user["is_admin"];
}

int is_list_owner(SpeedyDelivery.Objects.List list, SpeedyDelivery.Objects.Subscriber user)
{
  return has_value(list["list_owners"], user);
}


void process_queue()
{
  object client = master()->resolv("Mail.RobustClient")(config["smtp"]->smtp_host ||"localhost", config["smtp"]->smtp_port||25);
Log.debug("have Mail.RobustClient.");
  client->process_queue((int)(config["smtp"]->queue_interval||60), (int)(config["smtp"]->queue_length||5760));
}

int|array send_message(string sender, array recipients, string message)
{
    return master()->resolv("Mail.RobustClient")(config["smtp"]->smtp_host, config["smtp"]->smtp_port||25)->send_message(
                   sender,
                   recipients, message);
}

int|array send_message_for_list(SpeedyDelivery.Objects.List list, array recipients, string message)
{
    return send_message(get_bounce_address(list),
                   recipients, message);
}

int|array send_message_to_list_owner(SpeedyDelivery.Objects.List list, string message)
{
    return send_message(get_install_address(),
                   get_owner_addresses(list), message);
}

string getmyhostname()
{
  return config["smtp"]["return_host"] || gethostname();
}

string get_install_address()
{
  return config["smtp"]["listmaster"];
}

array(string) get_owner_addresses(SpeedyDelivery.Objects.List list)
{
  return list["list_owners"]["email"];
}

string get_bounce_address(SpeedyDelivery.Objects.List list)
{
  return get_address_for_function(list, "bounces");
}

string get_address_for_function(SpeedyDelivery.Objects.List list, string func)
{
  if(func == "__default") func = 0;

  return list["name"] + (func?("-" + func):"") + "@" + getmyhostname();
}

string get_listmaster_address()
{
  return config["smtp"]["listmaster"];
}

int send_message_as_attachment_to_list_owner(SpeedyDelivery.Objects.List list, string subject, string message, MIME.Message mime)
{
    object wm;
    object att = MIME.Message((string)mime);

    att->headers["content-disposition"]="attachment";
    att->setdisp_param("filename", att->headers["subject"]);
    att = MIME.Message((string)att, (["content-type": "message/rfc822"]));

    wm = MIME.Message(message,
         (["content-type": "multipart/mixed", "subject": subject]),
              ({MIME.Message(message, ([]))}) + ({att}));

    return send_message_to_list_owner(list, (string)wm);
}


int generate_help(SpeedyDelivery.Request r)
{
  return 250;
}

int user_filter(function yield, Fins.Request id, Fins.Response response, mixed ... args) 
{

   yield();
   mixed d = response->template_data;
   if(d)
   {
     d->add("user", id->misc->session_variables->user);
     d->add("request", id);
     d->add("controller", get_path_for_controller(id->controller));
   }   
   return 1;
}

int mandatory_user_filter(function yield, Fins.Request id, Fins.Response response, mixed ... args)
{
   if(!id->misc->session_variables->user)
   {
      response->flash("msg", "You must login to perform this action.");
      response->redirect(controller->auth->login, 0, ([ "return_to": id->not_query ]));
      return 0;
   }

   yield();

   mixed d = response->template_data;

   if(d)
   {
     mapping p = config["full_text"];
      if(p) d->add("have_fulltext", 1);

     d->add("user", id->misc->session_variables->user);
     d->add("request", id);
     d->add("controller", get_path_for_controller(id->controller));
   }

   return 1;
}

mixed is_valid_address(Mail.MailAddress a)
{
  // if we already know that the address is okay, we just go with it.
  array r;

  a->localpart = lower_case(a->localpart);

  if(r = valid_addresses[a->localpart])
  {
     Log.debug("list: %O, function: %O", r[0], r[1]);
     return r;
  }
  // otherwise, we need to figure it out.
  // list addresses look like this: listname(-functionname)
  // where listname cannot contain ("-" + any registered functionname).
  array x = a->localpart/"-";

  string functionname;

  if(sizeof(x) > 1) // okay, we have a -, we need to figure if it's
                    // part of the list name, or an admin function.
  {
    if(destination_handlers[x[-1]])
    {
       functionname = x[-1];
       x = x[0.. sizeof(x) - 2];
    }
  }

  object l;

werror("looking for %O\n", x);

  if(catch(l = ds->find->lists_by_alt(x*"-")))
  {
    Log.info("%s is not a valid list identifier.", a->localpart);
    return 0;
  }

  Log.debug("list: %O, function: %O", l["name"], functionname);

  valid_addresses[a->localpart] = ({l["name"], functionname || "__default"});

  return valid_addresses[a->localpart];
}


void distribute_message(SpeedyDelivery.Request r)
{
   function_object(destination_handlers->__default)->do_post(r);
} 
