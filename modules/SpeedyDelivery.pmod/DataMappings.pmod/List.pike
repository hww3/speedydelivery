// auto-generated by Fins.AdminTools.ModelBuilder for table lists.

inherit Fins.Model.DataObject;

void post_define(object context)
{
// Add any post configuration logic here
  add_field(context, Fins.Model.MetaDataField("_options", "options"));
  add_field(context, Fins.Model.TransformField("_addresses", "name", gen_addresses));
  has_many_to_many(context, "lists_owners", "Subscriber", "owned_list", "list_owner");

//  set_alternate_key("name");
}

mapping gen_addresses(mixed n, object i)
{
   mapping a = ([]);

   foreach(i->context->app->destination_handlers; string k; mixed v)
   {
     a[k] = i->context->app->get_address_for_function(i, k);
   }
 return a;
}
