inherit SpeedyDelivery.Plugin;

import Tools.Logging;

constant name = "bounce support";
constant description = "support for handling bounces";

int _enabled = 1;

mapping query_destination_callers()
{
  return (["bounces": handle_bounce]);
}

int handle_bounce(SpeedyDelivery.Request r)
{
  Log.info("the following bounce was received: %O", r->mime->headers);
  Stdio.write_file("/tmp/spdbounce.txt", (string)r->mime);
  return 0;
}
