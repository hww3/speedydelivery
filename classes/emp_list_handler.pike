inherit "list_handler";

import Tools.Logging;


int handle_post(SpeedyDelivery.Request request)
{
  return 250;
}

// TODO this should be asynchronous.
void do_post(object request)
{
   array fails;
 
   int res = app->trigger_event("preDelivery",
             (["request": request, "mime": request->mime, "list": request->list]));
   if(res == SpeedyDelivery.abort) return 0;

    rewrite_message(request, request->mime);

    mixed e;
    
    array subscribers = Fins.Model.get_context("_default")
      ->find->subscriptions((["List": request->list]))[*]["Subscriber"];
      
    foreach(subscribers;; object subscriber)
    {
      e = catch {
        object m = tailor_message(request->mime, (["recipient": subscriber, "campaign": request->list]));
        werror("email: %O\n", subscriber["email"]);
        fails = app->send_message_for_list(request->list, 
          ({subscriber["email"]}), (string)m);
      };
      if(e)
      {
        Log.warn("an error occurred while sending a message.");
        Log.exception("error", e);
      }
      if(fails) // immediate failures
      {
        Log.debug("the following failures occurred: %O", fails);
        array f = Fins.DataSource._default.find.subscribers(
                           (["email": Fins.Model.InCriteria(fails)]));
        foreach(f;; object fa)
        {
      		int i = fa["bounces"];
  	    	fa["bounces"] = (i+1);
        }        
      }
    }

    if(app->trigger_event("postDelivery",
             (["request": request, "list": request->list, "mime": request->mime]))
      == SpeedyDelivery.abort) return 0;

  return 0;
}

MIME.Message tailor_message(MIME.Message message, mapping data)
{
  object m = MIME.Message((string)message);
  m->headers->to = (string)data->recipient["email"];
  return m;
}

void rewrite_message(SpeedyDelivery.Request request, MIME.Message mime)
{
//  mime->headers["list-id"] = "<" +  request->list_address + ">";
  mime->headers["x-loop"] = request->list_address;
  mime->headers["x-list"] = replace(request->list_address, "@", ".");
  mime->headers["x-resent-by"] = "SpeedyDelivery";
  
//  mime->headers["list-post"] = "<mailto:" + 
//              request->list["_addresses"]["__default"] + ">"; 
//  mime->headers["list-owner"] = "<mailto:" + 
//              request->list["_addresses"]["owner"] + ">"; 
//  mime->headers["list-subscribe"] = "<mailto:" + 
//    request->list["_addresses"]["subscribe"] + "?subject=subscribe>";
//  mime->headers["list-unsubscribe"] = "<mailto:" + 
//    request->list["_addresses"]["unsubscribe"]+ "?subject=unsubscribe>";

  // TODO: we really need to come up with something better,
  // like the algorithm we use in Response->redirect.
//  mime->headers["list-help"] = "<" + 
//     "http://" + app->config["smtp"]["return_host"] +
//     app->url_for_action(app->controller->listinfo, 
//                 ({request->list["name"]})) + ">";

//  if(request->list["_options"]["replies_to_list"])
//    mime->headers["reply-to"] = request->list["_addresses"]["__default"];


  if(request->list->trigger_event("rewriteMessage",
             (["request": request, "mime": mime]))
      == SpeedyDelivery.abort) return 0;
}

