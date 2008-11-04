//!
constant abort = 1;

//!
constant ok = 0;

//!
constant STRING = 1;

//!
constant BOOLEAN = 2;

//!
constant INTEGER = 4;


//! gets all of the parts of the message that are of type text/*
string getfullbodytext(object mime, string|void s)
{
  if(!s) s = "";
  if(!mime->headers["content-type"] || has_prefix(lower_case((string)mime->headers["content-type"]), "text/"))
    s += mime->getdata();

  if(mime->body_parts)
  {
    foreach(mime->body_parts;; object nm)
      s += getfullbodytext(nm, s);
  }

  return s;
}

//! gets all of the parts of the message that are of type mt, defaults
//! to text/plain.
string getfullbodymimetext(object mime, string mt, string|void s)
{
  if(!mt) mt = "text/plain";
  if(!s) s = "";
  if(has_prefix(mime->headers["content-type"], mt))
    s += mime->getdata();

  if(mime->body_parts)
  {
    foreach(mime->body_parts;; object nm)
      s += getfullbodymimetext(nm, mt, s);
  }

  return s;
}



