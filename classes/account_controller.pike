inherit Fins.DocController;

int __quiet = 1;

static void start()
{
  around_filter(app->mandatory_user_filter);
}

void index(object id, object response, object view, mixed args)
{
  object user = id->misc->session_variables->user;
}


void update(object id, object response, object view, mixed args)
{
  object user = id->misc->session_variables->user;

  if(id->variables->action == "update")
  {
      if(id->variables->name && sizeof(id->variables->name))
      {
        user["name"] = id->variables->name;
        response->flash("Your account information was successfully changed.");
      }
  }  
  else if(id->variables->action == "password")
  {
    if(!(id->variables->reset_1) || sizeof(id->variables->reset_1) < 4)
    {
      response->flash("Your password must be at least 4 characters long.");
    }
    else if(id->variables->reset_1 != id->variables->reset_2)
    {
      response->flash("Your passwords do not match.");
    }
    else
    {
      user["password"] = id->variables->reset_1;
      response->flash("Your password was successfully changed.");
    }
  }

  response->redirect(index, ({(string)time()}));

  return;
}
