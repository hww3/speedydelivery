// handler for the list post address

import Tools.Logging;
inherit Fins.FinsBase;

int handle_post(SpeedyDelivery.Request request)
{
   array fails;

    mapping o = request->list["_options"];

    if(o->reject_non_subscribers)
    {
       Log.debug("checking to see if the sender is a subscriber.");
       if(!sizeof(Fins.Model.find.subscriptions(
                (["Subscriber": Fins.Model.find.subscribers_by_alt(request->sender->get_address()),
                 "List": request->list ]))))
      {
        Log.debug("sender isn't a subscriber. sending a failure message.");
        object mime = MIME.Message();
        mime->headers["subject"] = "message posting denied";
        mime->headers["to"] = request->sender->get_address();
        mime->headers["from"] = app->get_bounce_address(request->list);
        mime->setdata("Your posting with the subject of:\n\n" + request->mime->headers->subject + "\n\nwas denied because list policy requires posters to subscribe.");
        catch(app->send_message_for_list(request->list, ({request->sender->get_address()}), (string)mime));

        return 250;
      }
    }

    if(app->trigger_event("preDelivery",
             (["request": request, "mime": request->mime, "list": request->list]))
      == SpeedyDelivery.abort) return 250;

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
      == SpeedyDelivery.abort) return 250;

  return 250;
}

void rewrite_message(SpeedyDelivery.Request request, MIME.Message mime)
{
  mime->headers["list-id"] = "<" +  request->list_address + ">";
  if(request->list->trigger_event("rewriteMessage",
             (["request": request, "mime": mime]))
      == SpeedyDelivery.abort) return;
}

