grammar comscan:host:analysis;

-- unparse
imports silver:langutil;

--

nonterminal Message with pp;

abstract production errMessage
top::Message ::= msg::String loc::Location
{ 
  top.pp = loc.unparse ++ ": error: " ++ msg ++ "\n";
}

abstract production tyWarning
top::Message ::= msg::String loc::Location
{
  top.pp = loc.unparse ++ ": type warning: " ++ msg ++ "\n";
}