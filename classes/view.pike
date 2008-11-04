
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
