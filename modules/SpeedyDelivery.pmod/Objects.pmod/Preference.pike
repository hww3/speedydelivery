// auto-generated by Fins.AdminTools.ModelBuilder.

inherit Fins.Model.DirectAccessInstance;

string type_name = "Preference";

mixed get_value()
{
  mixed val;

  switch((int)this["type"])
  {
    case SpeedyDelivery.INTEGER:
      val = (int)this["value"];
      break;
    case SpeedyDelivery.STRING:
      val = this["value"];
      break;
    case SpeedyDelivery.BOOLEAN:
      val = ((int)this["value"])?1:0;
      break;
  }

  return val;
}
