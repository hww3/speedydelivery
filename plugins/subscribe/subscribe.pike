inherit SpeedyDelivery.Plugin;

constant name = "subscribe support";
constant description = "support for subscription via email";

int _enabled = 1;

mapping query_destination_callers()
{
  return (["subscribe": handle_subscribe]);
}

int handle_subscribe(SpeedyDelivery.Request r)
{

}
