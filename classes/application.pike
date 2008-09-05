import Tools.Logging;

inherit Fins.Application;

mapping plugins = ([]);
mapping event_handlers = ([]);
mapping destination_handlers = ([]);
mapping valid_addresses = ([]);

void start()
{
  load_default_destination_handler();
  load_plugins();
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
  catch(p = Fins.Model.find.preferences_by_alt(pref));
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
     p = Fins.Model.new("Preference");
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
     p = Fins.Model.new("Preference");
     p["name"] = pref;
     p["type"] = type;
     p["description"] = "";
     p["value"] = value;
     p->save();
     return p;
  }
}


int|array send_message(string sender, array recipients, string message)
{
    return Mail.RobustClient(config["smtp"]->host, 25)->send_message(
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
   }   
   return 1;
}

