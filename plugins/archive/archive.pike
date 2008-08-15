inherit SpeedyDelivery.Plugin;
import Tools.Logging;

constant name = "archive support";
constant description = "support for archived article storage";

int _enabled = 1;

mapping query_event_callers()
{
  return ([ ]);
}

mapping query_destination_callers()
{
  return ([ ]);
}

