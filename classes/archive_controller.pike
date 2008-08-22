inherit Fins.DocController;
int __quiet = 1;

void list(object id, object response, object view, mixed args)
{
  object list = Fins.Model.find.lists_by_alt(args[0]);
}

void display(object id, object response, object v, mixed args)
{
  object list = Fins.Model.find.lists_by_alt(args[0]);

  array mails = Fins.Model.find.archived_messages(
                               (["id":(int)args[1], "List": list]));
  if(!mails || !sizeof(mails))
  {
    response->flash("Requested Mail/List does not exist.");
    response->redirect(id->referrer || app->controller);
  }
  v->add("list", list);
  v->add("mail", mails[0]);
  v->add("mime", message(mails[0]["content"]));
}


class message
{
  inherit MIME.Message;

  string body;

  static void create(string c)
  {
    ::create(c);
    body = SpeedyDelivery.getfullbodymimetext(this,body);   
  }
}
