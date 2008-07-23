//! this is a template for a SpeedyDelivery plugin

Fins.Application app;

constant name = "";
constant description = "";
string module_dir = "";

int _enabled = 0;

void create(Fins.Application _app)
{
	app = _app;
}

int installed();

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

mapping query_event_callers();

mapping query_destination_callers();

//! @returns a mapping containing localprefname : ([ "type": FinScribe.STRING|FinScribe.BOOLEAN, "value": defaultvalue])
//!    pairs. these will be automatically created if they don't exist.
mapping(string:mapping) query_preferences();
