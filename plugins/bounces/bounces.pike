inherit SpeedyDelivery.Plugin;

import Tools.Logging;

constant name = "bounce support";
constant description = "support for handling bounces";

int _enabled = 1;

/*
   some regular expressions we've shamelessly borrowed from
   smartlist's etc/rc.request
*/

constant transient_bounce_subject = 
"(Warning - delayed mail|(WARNING: message ([^      ]+ )?|Mail )delayed|"
"(Returned mail: )?(warning: c(an|ould )not send m(essage fo|ail afte)r|Unbalanced '\"'|"
"Cannot send (within [0-9]|8-bit data to 7-bit)|"
"Data format error|Headers too large|Eight bit data not allowed|"
"Message (size )?exceeds (fixed )?maximum (fixed|message) size)|"
"Undeliverable (RFC822 )?mail: temporarily unable to deliver|"
"\\*\\*\\* WARNING - Undelivered mail in mailqueue|Execution succee?ded)";

constant warning_subject =
"(Warning from|mail warning| ?Waiting mail)";

constant warning_senders =
".*(uucp|mmdf)";

constant warning_removed = 
"You have been removed from";

constant x_loop_bounce =
"\(bounce\)";

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

int is_bounce(SpeedyDelivery.Request r)
{
  object regexp = Regexp.SimpleRegexp(transient_bounce_subject);

  if(regexp->match(r->mime->headers["subject"]))
    return 0;

  regexp = Regexp.SimpleRegexp(warning_senders);
  if(regexp->match(r->mime->headers["from"]))
    return 0;
  if(regexp->match(r->mime->headers["sender"]))
    return 0;

  regexp = Regexp.SimpleRegexp(warning_subject);
  if(regexp->match(r->mime->headers["subject"]))
    return 0;

  regexp = Regexp.SimpleRegexp(warning_removed);
  if(regexp->match(r->mime->headers["subject"]))
    return 0;

  regexp = Regexp.SimpleRegexp(x_loop_bounce);
  if(regexp->match(r->mime->headers["x-loop"]))
    return 0;
}
