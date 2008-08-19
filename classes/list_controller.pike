inherit Fins.DocController;


void index(object id, object response, object view, mixed args)
{
  view->add("list", Fins.Model.find.lists_by_alt(args[0]));
}
