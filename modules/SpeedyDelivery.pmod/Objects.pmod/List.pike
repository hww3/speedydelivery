// auto-generated by Fins.AdminTools.ModelBuilder.

inherit Fins.Model.DirectAccessInstance;
object repository = Fins.Model;
string type_name = "List";

void set_options(mapping options)
{
  this["options"] = encode_value(options);
}

mapping get_options()
{
  string t = this["options"];

  if(t)
  {
    return decode_value(t);
  }
  return ([]);
}
