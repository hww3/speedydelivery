
inherit Fins.FinsView;

string simple_macro_speedydelivery_url(Fins.Template.TemplateData data, 
mapping|void args)
{
  return app->config["web"]["url"];
}

string simple_macro_human_email(Fins.Template.TemplateData data,
mapping|void args)
{
  if(args->var)
    return replace(args->var, ({"@", "."}), ({" at ", " dot "}));
  else
    return "human_email: NO VAR SUPPLIED";
}

string simple_macro_format_mail_address(Fins.Template.TemplateData data, 
mapping|void args)
{
  if(args->var)
  {
     object addr;
     catch(addr = Mail.MailAddress(args->var));

     if(addr)
     {
        if(args->full)
        {
           return replace((string)addr, ({"<", ">", "&"}), ({"&lt;", "&gt;", "&amp;"}));
        }
        else if(args->name)
        {
           return replace(addr->name, ({"<", ">", "&"}), ({"&lt;", "&gt;", "&amp;"}));
        }
	else
	{
           return replace(addr->get_address(), ({"<", ">", "&"}), ({"&lt;", "&gt;", "&amp;"}));
	}
     }
     
  }

  else return "<!-- no address available -->";
}
