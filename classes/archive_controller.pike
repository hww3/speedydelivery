inherit Fins.DocController;
int __quiet = 1;

void list(object id, object response, object view, mixed args)
{
  if(!args || !sizeof(args))
  {
    response->flash("msg", "No list specified.");
    response->redirect(index);
    return;
  }

  object list = Fins.DataSource._default.find.lists_by_alt(args[0]);

  if(!list)
  {
    response->flash("msg", "List " + args[0] + " not found.");
    response->redirect(index);
    return;
  }

  array x = Fins.DataSource._default.query(
	"SELECT strftime(archived_messages.archived, '%m%Y') AS date_group, COUNT(*) FROM archived_messages "
	"WHERE list_id = " + list["id"]  +
	" GROUP BY date_group"
	);

  view->add("list", list);
}

void index(object id, object response, object v, mixed args)
{
}

void display(object id, object response, object v, mixed args)
{
  object mail = Fins.DataSource._default.find.archived_messages_by_id((int)args[0]);
  if(!mail)
  {
    response->flash("Requested Mail does not exist.");
    response->redirect(id->referrer || app->controller);
  }
  v->add("list", mail["List"]);
  v->add("mail", mail);
  v->add("mime", message(mail["content"]));
}


class message
{
  inherit MIME.Message;

  string body;

  static void create(string c)
  {
    ::create(c);
    body = SpeedyDelivery.getfullbodymimetext(this);
  }
}
