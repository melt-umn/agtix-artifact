grammar comscan:host:analysis;

imports silver:compiler:extension:scopegraphs;

--

-- Scope graph and scope attributes:

scope labels 
  `lex, `var, `event, `handles, `par, `field, `file, 
  `imp, `actor, `inst, `conn, `action, `child, `handler 
as CSLabels;

scope attribute s;
scope attribute s_def;


-- Scope data productions:

attribute loc occurs on Datum;

abstract production datumActor
top::Datum ::= node::Decorated ActorDcl
{ 
  top.loc = node.location;
}

abstract production datumVar
top::Datum ::= node::Decorated Dcl
{ 
  top.loc = node.location;
}

abstract production datumConn
top::Datum ::= node::Decorated Connection
{
  top.loc = node.location;
}

abstract production datumEvent
top::Datum ::= node::Decorated EventTypeDcl
{
  top.loc = node.location;
}

abstract production datumFile
top::Datum ::= node::Decorated FileUnit
{
  top.loc = node.location;
}

abstract production datumInst
top::Datum ::= node::Decorated InstantiateDcl
{
  top.loc = node.location;
}

abstract production datumAction
top::Datum ::= node::Decorated Action
{
  top.loc = node.location;
}

abstract production datumHandler
top::Datum ::= node::Decorated Handler
{
  top.loc = node.location;
}

aspect default production top::Datum ::=
{
  top.loc = bogusLoc();
}

-- Default scope for error handling:

global deadScope::Decorated Scope with CSLabels = 
  decorate scope(datumDefault()) with { 
    lex = []; var = []; event = []; handles = [];
    par = []; field = []; file = []; imp = [];
    actor = []; inst = []; conn = []; action = [];
    child = []; handler = [];
  };

-- Query predicates:

fun isName (Boolean ::= Datum) ::= lookupName::String =
  \d::Datum ->
    let foundName::String =
      case d of
      | datumActor(node) -> node.name
      | datumVar(node) -> node.name
      | datumConn(node) -> node.name
      | datumEvent(node) -> node.name
      | datumFile(node) -> node.name
      | datumInst(node) -> node.name
      | datumAction(node) -> node.name
      | datumHandler(node) -> node.name
      | _ -> ""
      end
    in
      foundName == lookupName
    end;

fun any (Boolean ::= Datum) ::= = 
  \d::Datum -> true;

fun isNameDupl (Boolean ::= Datum) ::= lookupName::String lookupLoc::Location =
  \d::Datum ->
    let nameLoc::(String, Location) =
      case d of
      | datumActor(node) -> (node.name, node.location)
      | datumVar(node) -> (node.name, node.location)
      | datumConn(node) -> (node.name, node.location)
      | datumEvent(node) -> (node.name, node.location)
      | datumFile(node) -> (node.name, node.location)
      | datumInst(node) -> (node.name, node.location)
      | datumAction(node) -> (node.name, node.location)
      | datumHandler(node) -> (node.name, node.location)
      | _ -> ("", bogusLoc())
      end
    in
      nameLoc.1 == lookupName &&
      nameLoc.2 != lookupLoc
    end;

fun eventChildOf (Boolean ::= Datum) ::= par::String =
  \d::Datum ->
    case d of
    | datumEvent(node) -> node.parentName.isJust && node.parentName.fromJust == par
    | _ -> false
    end;
