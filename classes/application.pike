import Tools.Logging;

inherit Fins.Application;

mapping plugins = ([]);
mapping event_handlers = ([]);
mapping destination_handlers = ([]);
mapping valid_addresses = ([]);

void start()
{
  load_plugins();
}

void load_plugins()
{
	string plugindir = Stdio.append_path(config->app_dir, "plugins");
	array p = get_dir(plugindir);
//	Log.info("current directory is " + getcwd());
	foreach(p||({});;string f)
	{
		if(f == "CVS") continue;
		
		Log.info("Considering plugin " + f);
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
//				Log.info("File: %O", p);
				if(Program.implements(p, SpeedyDelivery.PluginInstaller) && !installer)
				  installer = p(this);
				else if(Program.implements(p, SpeedyDelivery.Plugin) && !module)
				  module = p(this);	
                                else continue;
                                module->module_dir = pd;
               
			}
			
			if(!module || module->name =="")
			{
				Log.error("Module %s has no name, not loading.", f);
				continue;
			}
			
			if(installer && functionp(installer->install) && module->installed())
			    installer->install(Filesystem.System(pd));
                        
			plugins[module->name] = module;
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
