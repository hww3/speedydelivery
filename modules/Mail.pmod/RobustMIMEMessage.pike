inherit MIME.Message;

string body;

static void create(string c)
{
  ::create(c);
  body = SpeedyDelivery.getfullbodymimetext(this);
}
