import Tools.Logging;

inherit "application";

string list_handler_prog = "emp_list_handler";


void start_plugins()
{
  plugins["unsubscribe support"]->_enabled = 0;
  plugins["subscribe support"]->_enabled = 0;
  plugins["archive support"]->_enabled = 0;
  plugins["digest delivery support"]->_enabled = 0;
  plugins["bounce support"]->_enabled = 1;
  ::start_plugins();
}