inherit SpeedyDelivery.Plugin;
import Tools.Logging;

constant name = "owner support";
constant description = "list owner email address";

int _enabled = 1;

mapping query_destination_callers()
{
  return (["owner": handle_owner]);
}

int handle_owner(SpeedyDelivery.Request r)
{
  app->send_message_to_list_owner(r->list, (string)(r->mime));
  return 250;
}

