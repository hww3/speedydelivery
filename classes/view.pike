
inherit Fins.FinsView;

string simple_macro_speedydelivery_url(Fins.Template.TemplateData data, 
mapping|void args)
{
  return app->config["web"]["url"];
}
