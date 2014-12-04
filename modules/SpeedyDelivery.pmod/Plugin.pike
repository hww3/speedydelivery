//! this is a template for a SpeedyDelivery plugin

import Tools.Logging;

Fins.Application app;

constant name = "";
constant description = "";
string module_dir = "";
constant list_enableable = 0;

int _list_enabled_default = 1;
int _enabled = 0;

void create(Fins.Application _app)
{
	app = _app;
}

int installed();

int list_enabled(SpeedyDelivery.Objects.List list)
{
  Log.debug("List enabled? %O for %O", this, list);
  if(list_enableable)
  {
    mapping o = list["_options"];
    if(!o["enabled_plugins"]) o["enabled_plugins"] = ([]);
    Log.debug("enabled plugins for list: looking for %O, have %O", name, o["enabled_plugins"]);
    return (o["enabled_plugins"][name]);
  }
  else return 0;
}

int enable_for_list(SpeedyDelivery.Objects.List list)
{
  if(list_enableable)
  {
    mixed o = list["_options"];
    if(!o["enabled_plugins"]) o["enabled_plugins"] = ([]);

    int n = o["enabled_plugins"][name];

    // metadata fields have trouble knowing when to save if you're manipulating 
    // data deep within the value. so, we force the save.
    o["enabled_plugins"][name] = 1;
    o->save();

    return (n);
  }
}

int enabled()
{
  mixed m;

  m = app->new_pref("plugin." + name + ".enabled", _enabled, SpeedyDelivery.BOOLEAN);
  return m->get_value();
}


void start();

void stop();

mixed get_preference(string pref)
{
  return app->get_sys_pref("plugin." + name + "." + pref);
}

mixed get_list_setting(string setting, object list)
{
  return list["_options"][("_plugin_"+ name + "_" + setting)];
}

mapping query_event_callers();

mapping query_destination_callers();

//! @returns a mapping containing localprefname : ([ "type": FinScribe.STRING|FinScribe.BOOLEAN, "value": defaultvalue])
//!    pairs. these will be automatically created if they don't exist.
mapping(string:mapping) query_preferences();

mapping(string:mapping) query_list_settings();
