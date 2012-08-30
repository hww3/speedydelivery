inherit Fins.DocController;
int __quiet = 1;

void start()
{
 // we probably need to filter based on subscription, as well.
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
    response->redirect(this->list, ({list["name"]}));
    return;
  }

  object month;

  catch(month = Calendar.parse("%Y-%M %D", args[1] + " 1")->month());

  if(!month)
  {
    response->flash("msg", "Invalid date range specified.");
    response->redirect(this->list, ({list["name"]}));
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

void search(object id, object response, object v, mixed args)
{
  mapping p = app->config["full_text"];
  if(!p)
  {
    response->flash("msg", "No full text engine configured.");
    response->redirect(messages, args);
    return;
  }

  if(!p["url"])
  {
    response->flash("msg", "No full text engine url configured");
    response->redirect(messages, args);
    return;
  }

  if(!args || !sizeof(args))
  {
    response->flash("msg", "No list specified.");
    response->redirect(index);
    return;
  }

  if(!id->variables->q)
  {
    response->flash("msg", "No search query provided.");
    response->redirect(this->list, args);
    return;
  }  

  object list = Fins.DataSource._default.find.lists_by_alt(args[0]);

  if(!list)
  {
    response->flash("msg", "List " + args[0] + " not found.");
    response->redirect(index);
    return;
  }

  string indexname = "SpeedyDelivery_" + args[0];

  object c = FullText.SearchClient(p["url"], indexname, p["auth"]);


  array x = c->search(id->variables->q);

  if(sizeof(x->handle))
    v->add("results", Fins.DataSource._default.find.archived_messages((["List": list["id"], "id": x->handle])));
  v->add("list", list);  
  v->add("q", id->variables->q);

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
  if(id->variables->ftq)
    v->add("ftq", id->variables->ftq);
  v->add("mime", Mail.RobustMIMEMessage(mail["content"]));
}
