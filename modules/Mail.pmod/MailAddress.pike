string name;
string localpart;
string host;

constant STATE_HAVE_AT = 2;
constant STATE_HAVE_LOCAL = 4;
constant STATE_HAVE_HOST = 8;
constant STATE_IN_ADDRESS = 16;


static void create(string address)
{
  array x = MIME.decode_words_tokenized_remapped(address);

  parse_tokens(x);
}


void parse_tokens(array t)
{
  int state;

  array scratch = ({});

  // okay, we start out with a state machine
  foreach(t; int i; string|int tok)
  {
     switch(tok)
     {
       case '<':
         if(state & STATE_IN_ADDRESS)
           throw(Error.Generic("invalid symbol '<' inside address\n"));

         state |= STATE_IN_ADDRESS;
         if(sizeof(scratch))
         {
           name = scratch * " ";
           scratch = ({});
         }
         break;

       case '>':
         // if we get to the end of the address and there's a token
         // it's the host part.
         if(! (state & STATE_HAVE_AT))
           throw(Error.Generic("invalid address: > before at sign.\n"));
         if(sizeof(scratch))
         {
           host = scratch*"";
           scratch = ({});
           state |= STATE_HAVE_HOST;
         }

         if(!((state & STATE_HAVE_LOCAL) && (state & STATE_HAVE_HOST)))
           throw(Error.Generic("address must have both local and host parts.\n"));
         state ^= STATE_IN_ADDRESS;
         break;

       case '@':
         //werror("have at\n");
         if(sizeof(scratch) ==1 )
         {
           //werror("adding " + (scratch *"") + " to local\n");
           localpart = scratch * "";
           scratch = ({});
           state |= STATE_HAVE_LOCAL;
         }
         else if(sizeof(scratch) > 1)
         {
           throw(Error.Generic("address may only have 1 token as a local-part.\n"));
         }
         else
           throw(Error.Generic("address must have a local-part.\n"));
         state |= STATE_HAVE_AT;
         break;

       case ',':
         break;

       default:
          if(intp(tok)) 
            throw(Error.Generic(sprintf("have unexpected token '%c' in address.\n", tok)));
          //werror("adding " + tok + " to scratch.\n");
          scratch += ({tok});
     }
  
  }

  // now, we deal with any remaining tokens in the scratchpad
  // if we get to the end and don't have locale at host, it's a failure.

  if(!((state & STATE_HAVE_AT) && (state & STATE_HAVE_LOCAL)))
    throw(Error.Generic("invalid address: missing local@.\n"));
  else if(!sizeof(scratch) && !(state & STATE_HAVE_HOST))
    throw(Error.Generic("invalid address: missing host.\n"));
  else if(sizeof(scratch) == 1 && (state & STATE_HAVE_AT) && !(state & STATE_HAVE_HOST))
  {
    state |= STATE_HAVE_HOST;
    host = scratch[0];
  } 
  else if(sizeof(scratch) > 1 && (state & STATE_HAVE_AT) && ! (state & STATE_HAVE_HOST))
  {
    throw(Error.Generic("invalid address: too much data following at.\n"));
  }
  else if(sizeof(scratch) && name)
  {
    throw(Error.Generic("invalid address: bogus trailing data, we already have a name.\n"));
  }
  else if(sizeof(scratch) && !name)
  {
    name = (scratch*" ");
  }

  // finally, we should check to see if the host portion is valid.
  if(localpart[0] == '.' || localpart[-1] == '.')
    throw(Error.Generic("invalid address: local part contains invalid characters.\n"));
  if(search(localpart, "..") != -1)
    throw(Error.Generic("invalid address: local part contains invalid characters.\n"));
  if(!equal(host/"" - ({"[", "]", "\"", "\n"}), host/"")) 
    throw(Error.Generic("invalid address: host part contains invalid characters.\n"));
}

string get_address()
{
  return localpart + "@" + host;
}

string _sprintf(mixed t)
{
  return (name?("\"" + name + "\" "):"") + "<" + get_address() + ">";
}

mixed cast(mixed t)
{
  if(t == "string")
    return (name?("\"" + name + "\" "):"") + "<" + get_address() + ">";
  else throw(Error.Generic("Cannot cast MailAddress to " + t + ".\n"));
}
