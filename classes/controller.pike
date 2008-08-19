
inherit Fins.DocController;

Fins.FinsController listinfo;
Fins.FinsController commands;

void start()
{
  listinfo = load_controller("list_controller");
  commands = load_controller("command_controller");
}


void index(object id, object response, object view, mixed ... args)
{
  view->add("lists", Fins.Model.find.lists(([]),
           Fins.Model.Criteria("ORDER BY name DESC")));
}

