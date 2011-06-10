inherit Fins.DocController;
int __quiet = 1;

void start()
{
    around_filter(app->mandatory_user_filter);
}

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
	"SELECT date_format(archived_messages.archived, '%Y-%m') AS date_group, COUNT(*) as message_count FROM archived_messages "
	"WHERE list_id = " + list["id"]  +
	" GROUP BY date_group HAVING message_count > 0 ORDER BY date_group"
	);

  foreach(x;;mapping y)
    y["nice_date_group"] = Calendar.parse("%Y-%M %D", y->date_group + " 1")->month();

  view->add("list", list);
  view->add("date_groups", x);
}

void messages(object id, object response, object view, mixed args)
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

  if(sizeof(args) < 2)
  {
    response->flash("msg", "No date range specified.");
    response->redirect(list, ({list["name"]}));
    return;
  }

  object month;

  catch(month = Calendar.parse("%Y-%M %D", args[1] + " 1")->month());

  if(!month)
  {
    response->flash("msg", "Invalid date range specified.");
    response->redirect(list, ({list["name"]}));
    return;
  }

  array messages = Fins.DataSource._default.find.archived_messages((["List": list, "archived": month]));
  view->add("list", list);
  view->add("date_range", month);
  view->add("messages", messages);
}

void index(object id, object response, object v, mixed args)
{
}

void display(object id, object response, object v, mixed args)
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

  object mail = Fins.DataSource._default.find.archived_messages((["List": list["id"], "id": (int)args[1]]))[0];
  if(!mail)
  {
    response->flash("Requested Mail does not exist.");
    response->redirect(id->referrer || app->controller);
  }
  object month = mail["archived"]->month();

  string ref = mail["referenceid"];
  string followups = mail["messageid"];

  if(ref)
  {
    array reference;
    reference = Fins.DataSource._default.find.archived_messages((["List": list["id"], "messageid": ref]));

    if(sizeof(reference))
      v->add("reference", reference[0]);
  }
  if(followups)
  {
    array reference;
    reference = Fins.DataSource._default.find.archived_messages((["List": list["id"], "referenceid": followups]));

    if(sizeof(reference))
      v->add("followups", reference);
  }
  v->add("list", mail["List"]);
  v->add("date_range", month);
  v->add("date_range_name", sprintf("%4d-%02d", month->year_no(), month->month_no()));
  v->add("mail", mail);
  v->add("mime", Mail.RobustMIMEMessage(mail["content"]));
}
