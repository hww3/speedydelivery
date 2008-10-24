// handler for the list post address

import Tools.Logging;
inherit Fins.FinsBase;

// list options:
//   reject_non_subscribers
//   replies_to_list

int handle_post(SpeedyDelivery.Request request)
{
    // first, check to see if we have an X-Loop header, and deal
    // with it appropriately.

    string xl = request->mime->headers["x-loop"];

    if(xl && lower_case(xl) == lower_case(request->list_address)) 
    {
      Log.info("Ignoring message with matching X-Loop header: %s", request->list_address);
      return 250;
    }
    mapping o = request->list["_options"];

    if(o->reject_non_subscribers)
    {
       Log.debug("checking to see if the sender is a subscriber.");
       object s;
       if(catch(s = Fins.Model.find.subscribers_by_alt(request->sender->get_address())) || 
           !sizeof(Fins.Model.find.subscriptions(
                (["Subscriber": Fins.Model.find.subscribers_by_alt(request->sender->get_address()),
                 "List": request->list ]))))
      {
        Log.debug("sender isn't a subscriber. sending a failure message.");
        object mime = MIME.Message();
        mime->headers["subject"] = "message posting denied";
        mime->headers["to"] = request->sender->get_address();
        mime->headers["from"] = app->get_bounce_address(request->list);
        mime->setdata("Your posting with the subject of:\n\n" + request->mime->headers->subject + "\n\nwas denied because list policy requires posters to subscribe."
		"\n\nIt has been sent to the list owner for review.\n");

        SpeedyDelivery.Objects.Held_message()->new_for_list_action(request->list, "nonmember", request->sender->get_address(), request->mime);
        catch(app->send_message_for_list(request->list, ({request->sender->get_address()}), (string)mime));

        return 250;
      }
    }

  do_post(request);
  return 250;
}

void do_post(object request)
{
   array fails;
 
   if(app->trigger_event("preDelivery",
             (["request": request, "mime": request->mime, "list": request->list]))
      == SpeedyDelivery.abort) return;

    rewrite_message(request, request->mime);

    if(catch(
      fails = app->send_message_for_list(request->list, 
                                         Fins.Model.find.subscriptions((["List": request->list, "mode": "M"]))["Subscriber"]["email"],
                                         (string)request->mime)
    )) Log.warn("an error occurred while sending a message.");

    if(fails)
    {
      Log.debug("the following failures occurred: %O", fails);
      array f = Fins.Model.find.subscribers(
                         (["email": Fins.Model.InCriteria(fails)]));
      f["bounces"]++;
    }

    if(app->trigger_event("postDelivery",
             (["request": request, "list": request->list, "mime": request->mime]))
      == SpeedyDelivery.abort) return;

  return;
}

void rewrite_message(SpeedyDelivery.Request request, MIME.Message mime)
{
  mime->headers["list-id"] = "<" +  request->list_address + ">";
  mime->headers["x-loop"] = request->list_address;
  mime->headers["x-list"] = replace(request->list_address, "@", ".");
  mime->headers["list-post"] = "<mailto:" + 
              request->list["_addresses"]["__default"] + ">"; 
  mime->headers["list-owner"] = "<mailto:" + 
              request->list["_addresses"]["owner"] + ">"; 
  mime->headers["list-subscribe"] = "<mailto:" + 
    request->list["_addresses"]["subscribe"] + "?subject=subscribe>";
  mime->headers["list-unsubscribe"] = "<mailto:" + 
    request->list["_addresses"]["unsubscribe"]+ "?subject=unsubscribe>";

  // TODO: we really need to come up with something better,
  // like the algorithm we use in Response->redirect.
  mime->headers["list-help"] = "<" + 
     "http://" + app->config["smtp"]["return_host"] +
     app->url_for_action(app->controller->listinfo, 
                 ({request->list["name"]})) + ">";

  if(request->list["_options"]["replies_to_list"])
    mime->headers["reply-to"] = request->list["_addresses"]["__default"];


  if(request->list->trigger_event("rewriteMessage",
             (["request": request, "mime": mime]))
      == SpeedyDelivery.abort) return;
}

