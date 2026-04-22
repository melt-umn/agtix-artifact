grammar comscan:host:analysis;

--

nonterminal Expr with location, msgs, s, type;

--propagate msgs on Expr excluding eventBuild;

abstract production boolOr
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, boolTy(location=top.location)) &&
       !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("left operand of || expected expression of type bool " ++ 
                      "or an expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, boolTy(location=top.location)) &&
       !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of || expected expression of type bool " ++ 
                      "or an expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if (tyEq(e1.type, boolTy(location=top.location))) && 
       (tyEq(e2.type, boolTy(location=top.location)))
    then boolTy(location=top.location)
    else termErrTy;
}

abstract production boolAnd
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, boolTy(location=top.location)) &&
       !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("left operand of && expected expression of type bool " ++
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, boolTy(location=top.location)) &&
       !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of && expected expression of type bool " ++
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, boolTy(location=top.location)) && 
       tyEq(e2.type, boolTy(location=top.location))
    then boolTy(location=top.location)
    else termErrTy;
}

abstract production bitOr
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, boolTy(location=top.location)) &&
       !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("left operand of | expected expression of type bool " ++ 
                      "or an expression of type int " ++
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, boolTy(location=top.location)) &&
       !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of | expected expression of type bool " ++ 
                      "or an expression of type int " ++
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if (tyEq(e1.type, boolTy(location=top.location)) || 
        tyEq(e1.type, intTy(location=top.location))) && 
       (tyEq(e2.type, boolTy(location=top.location)) ||
        tyEq(e2.type, intTy(location=top.location)))
    then intTy(location=top.location)
    else termErrTy;
}

abstract production bitAnd
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, boolTy(location=top.location)) &&
       !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("left operand of & expected expression of type bool " ++ 
                      "or an expression of type int " ++
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, boolTy(location=top.location)) &&
       !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of & expected expression of type bool " ++ 
                      "or an expression of type int " ++
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if (tyEq(e1.type, boolTy(location=top.location)) || 
        tyEq(e1.type, intTy(location=top.location))) && 
       (tyEq(e2.type, boolTy(location=top.location)) ||
        tyEq(e2.type, intTy(location=top.location)))
    then intTy(location=top.location)
    else termErrTy;
}

abstract production bitNeg
top::Expr ::= e::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e.type, intTy(location=top.location))
    then [ errMessage("operand of ~ expected expression of type int " ++ 
                      "or an expression of type int " ++ 
                      "but received expression of type " ++ e.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e.type, intTy(location=top.location)) ||
       tyEq(e.type, intTy(location=top.location))
    then intTy(location=top.location)
    else termErrTy;
}

abstract production eqComp
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    case e1.type, e2.type of
    | errTy(), _ -> [] | _, errTy() -> []
    | t1, t2 when tyEq(t1, t2) -> []
    | _, _ -> [ errMessage("left operand of == has type " ++ e1.type.strRep ++
                           " but right operand has type " ++ e2.type.strRep,
                           top.location) ]
    end;

  top.type = 
    if tyEq(e1.type, e2.type)
    then boolTy(location=top.location)
    else termErrTy;
}

abstract production neqComp
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    case e1.type, e2.type of
    | errTy(), _ -> [] | _, errTy() -> []
    | t1, t2 when tyEq(t1, t2) -> []
    | _, _ -> [ errMessage("left operand of != has type " ++ e1.type.strRep ++
                           " but right operand has type " ++ e2.type.strRep,
                           top.location) ]
    end;

  top.type = 
    if tyEq(e1.type, e2.type)
    then boolTy(location=top.location)
    else termErrTy;
}

abstract production gtComp
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, intTy(location=top.location))
    then [ errMessage("left operand of > expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of > expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, intTy(location=top.location)) && 
       tyEq(e2.type, intTy(location=top.location))
    then boolTy(location=top.location)
    else termErrTy;
}

abstract production ltComp
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, intTy(location=top.location))
    then [ errMessage("left operand of < expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of < expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, intTy(location=top.location)) && 
       tyEq(e2.type, intTy(location=top.location))
    then boolTy(location=top.location)
    else termErrTy;
}

abstract production geComp
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, intTy(location=top.location))
    then [ errMessage("left operand of >= expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of >= expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, intTy(location=top.location)) && 
       tyEq(e2.type, intTy(location=top.location))
    then boolTy(location=top.location)
    else termErrTy;
}

abstract production leComp
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, intTy(location=top.location))
    then [ errMessage("left operand of <= expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of <= expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, intTy(location=top.location)) && 
       tyEq(e2.type, intTy(location=top.location))
    then boolTy(location=top.location)
    else termErrTy;
}

abstract production lshift
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, intTy(location=top.location))
    then [ errMessage("left operand of << expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of << expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, intTy(location=top.location)) && 
       tyEq(e2.type, intTy(location=top.location))
    then intTy(location=top.location)
    else termErrTy;
}

abstract production rshift
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, intTy(location=top.location))
    then [ errMessage("left operand of >> expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of >> expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, intTy(location=top.location)) && 
       tyEq(e2.type, intTy(location=top.location))
    then intTy(location=top.location)
    else termErrTy;
}

abstract production append
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, stringTy(location=top.location))
    then [ errMessage("left operand of ++ expected expression of type string " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, stringTy(location=top.location))
    then [ errMessage("right operand of ++ expected expression of type string " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, stringTy(location=top.location)) && 
       tyEq(e2.type, stringTy(location=top.location))
    then stringTy(location=top.location)
    else termErrTy;
}

abstract production plus
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, intTy(location=top.location))
    then [ errMessage("left operand of + expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of + expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, intTy(location=top.location)) && 
       tyEq(e2.type, intTy(location=top.location))
    then intTy(location=top.location)
    else termErrTy;
}

abstract production minus
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, intTy(location=top.location))
    then [ errMessage("left operand of - expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of - expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, intTy(location=top.location)) && 
       tyEq(e2.type, intTy(location=top.location))
    then intTy(location=top.location)
    else termErrTy;
}

abstract production mult
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, intTy(location=top.location))
    then [ errMessage("left operand of * expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of * expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, intTy(location=top.location)) && 
       tyEq(e2.type, intTy(location=top.location))
    then intTy(location=top.location)
    else termErrTy;
}

abstract production mod
top::Expr ::= e1::Expr e2::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e1.type, intTy(location=top.location))
    then [ errMessage("left operand of % expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.msgs <- 
    if !tyEq(e2.type, intTy(location=top.location))
    then [ errMessage("right operand of % expected expression of type int " ++ 
                      "but received expression of type " ++ e1.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e1.type, intTy(location=top.location)) && 
       tyEq(e2.type, intTy(location=top.location))
    then intTy(location=top.location)
    else termErrTy;
}

abstract production numNeg
top::Expr ::= e::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e.type, intTy(location=top.location))
    then [ errMessage("operand of - expected expression of type int " ++ 
                      "but received expression of type " ++ e.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e.type, intTy(location=top.location))
    then intTy(location=top.location)
    else termErrTy;
}

abstract production boolNeg
top::Expr ::= e::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e.type, boolTy(location=top.location))
    then [ errMessage("operand of ! expected expression of type bool " ++ 
                      "but received expression of type " ++ e.type.strRep,
                      top.location) ]
    else [];

  top.type = 
    if tyEq(e.type, boolTy(location=top.location))
    then boolTy(location=top.location)
    else termErrTy;
}

abstract production var
top::Expr ::= name::String
{
  propagate msgs;

  local res::[Decorated Scope with CSLabels] =
    query(`lex* `var, isName(name), top.s);

  top.type =
    case res of
    | s::_ ->
      case s.datum of
      | datumVar(node) -> node.type
      | _ -> termErrTy
      end
    | _ -> termErrTy
    end;

  top.msgs <-
    if length(res) > 1
    then [ errMessage("ambiguous name reference " ++ name, top.location) ]
    else if length(res) < 1
    then [ errMessage("unresolvable name reference " ++ name, top.location) ]
    else [];
}

abstract production intConst
top::Expr ::= num::Integer
{
  propagate msgs;

  top.type = intTy(location=top.location);
}

abstract production trueConst
top::Expr ::=
{
  propagate msgs;

  top.type = boolTy(location=top.location);
}

abstract production falseConst
top::Expr ::=
{
  propagate msgs;

  top.type = boolTy(location=top.location);
}

abstract production stringConst
top::Expr ::= str::String
{
  propagate msgs;

  top.type = stringTy(location=top.location);
}

abstract production eventBuild
top::Expr ::= name::String fields::BuildEventFields
{
  propagate s;

  local eventRes::[Decorated Scope with CSLabels] = 
    query(`lex* `imp? `event, isName(name), top.s);

  fields.eventScope = case eventRes of
                      | s::_ -> s
                      | _ -> deadScope
                      end;
  fields.eventName = case top.type of
                     | nameEventTy(n) -> n
                     | _ -> "<err>"
                     end;

  production attribute eventDcl::Decorated EventTypeDcl = 
    case eventRes of
    | s::_ -> case s.datum of
              | datumEvent(node) -> node
              | _ -> error("eventBuild.eventDcl 1")
              end
    | _ -> error("eventBuild.eventDcl 2")
    end;

  -- below: check all fields covered
  
  local fieldNames::[String] = map (
    \s::Decorated Scope with CSLabels -> 
      case s.datum of datumVar(node) -> node.name 
                    | _ -> error("eventBuild.fieldNames") end,
    query(`field, any(), fields.eventScope)
  );
  local undefinedFields::[String] = removeAll(fields.fieldsHandled, fieldNames);

  top.msgs <-
    if !null(undefinedFields)
    then map(
      \field::String -> errMessage("field " ++ field ++ 
                                   " not defined for event " ++ name, top.location),
      undefinedFields
    )
    else [];

  -- above: check all fields covered

  top.type = if length(eventRes) == 1
             then nameEventTy(name, location=top.location)
             else termErrTy;

  top.msgs := if length(eventRes) > 1
              then [ errMessage("ambiguous event type reference " ++ name, top.location) ]
              else if length(eventRes) < 1
              then [ errMessage("unresolvable event type reference " ++ name, top.location) ]
              else fields.msgs;
}

abstract production fieldAccess
top::Expr ::= e::Expr field::String
{
  propagate s, msgs;

  local eventFields::[Decorated Scope with CSLabels] =
    case e.type of
    | nameEventTy(n) ->
      let resEvent::[Decorated Scope with CSLabels] = query(`lex* `imp? `event, isName(n), top.s)
      in concat(map(\s::Decorated Scope with CSLabels -> query(`field, isName(field), s), resEvent)) end
    | _ -> []
    end;

  top.type = 
    case eventFields of
    | s::[] -> case s.datum of | datumVar(node) -> node.type | _ -> termErrTy end
    | _ -> termErrTy
    end;

  top.msgs <- case e.type of
              | nameEventTy(_) -> [] | errTy() -> []
              | _ -> [ errMessage("left side of field access must have event type", top.location) ]
              end;

  top.msgs <- if length(eventFields) > 1
              then [ errMessage("ambiguous field reference " ++ field, top.location) ]
              else if length(eventFields) < 1
              then [ errMessage("unresolvable field reference " ++ field, top.location) ]
              else [];
}

abstract production toStr
top::Expr ::= e::Expr
{
  propagate s, msgs;

  top.msgs <- 
    if !tyEq(e.type, intTy(location=top.location))
    then [ errMessage("operand of toStr expected expression of type int " ++ 
                      "but received expression of type " ++ e.type.strRep,
                      top.location) ]
    else [];

  top.type = stringTy(location=top.location);
}

abstract production scan
top::Expr ::= 
{
  propagate msgs;
  
  top.type = stringTy(location=top.location);
}

abstract production hasKey
top::Expr ::= table::Expr key::Expr
{
  propagate s, msgs;
  
  top.type = boolTy(location=top.location);

  top.msgs <-
    case table.type, key.type of
    | tableTy(kt, _, _), rt when tyEq(^kt, rt) -> []
    | tableTy(kt, _, _), rt ->
      [ errMessage("table has key type " ++ kt.strRep ++ " but was accessed " ++ 
                   " with an expression of type " ++ rt.strRep, top.location) ]
    | _, _ ->
      [ errMessage("hasKey expected a table as its left operand " ++ 
                   "but received an expression of type " ++ key.type.strRep,
                   top.location) ]
    end;
}

abstract production index
top::Expr ::= table::Expr key::Expr
{
  propagate s, msgs;

  top.type =
    case table.type of
    | tableTy(kt, vt, _) when tyEq(^kt, key.type) -> ^vt
    | _ -> termErrTy
    end; 

  top.msgs <-
    case table.type, key.type of
    | tableTy(kt, _, _), rt when tyEq(^kt, rt) -> []
    | tableTy(kt, _, _), rt ->
      [ errMessage("table has key type " ++ kt.strRep ++ " but was accessed " ++ 
                   " with an expression of type " ++ rt.strRep, top.location) ]
    | _, _ ->
      [ errMessage("table index expected a table as its left operand " ++ 
                   "but received an expression of type " ++ key.type.strRep,
                   top.location) ]
    end;
}

--

inherited attribute eventScope::Decorated Scope with CSLabels;
inherited attribute eventName::String;
synthesized attribute fieldsHandled::[String];

nonterminal BuildEventFields with location, msgs, s, eventScope, eventName, fieldsHandled;
--propagate msgs, s, eventScope on BuildEventFields;

abstract production consBuildEventFields
top::BuildEventFields ::= name::String e::Expr m2::BuildEventFields
{
  propagate msgs, s, eventScope, eventName;

  local fieldRes::[Decorated Scope with CSLabels] =
    query(`field, isName(name), top.eventScope);

  top.fieldsHandled = name::m2.fieldsHandled;

  top.msgs <- 
    case fieldRes of
    | s::[] -> 
        case s.datum of 
        | datumVar(node) when !tyEq(node.type, e.type) ->
          [ errMessage("field " ++ name ++ " of event " ++ top.eventName ++ 
                       " expected type " ++ node.type.strRep ++ 
                       " but received " ++ e.type.strRep, top.location) ]
        | datumVar(_) -> []
        | _ -> []
        end
    | _ -> []
    end;

  top.msgs <- if length(fieldRes) > 1
              then [ errMessage("ambiguous field reference " ++ name, top.location) ]
              else if length(fieldRes) < 1
              then [ errMessage("unresolvable field reference " ++ name, top.location) ]
              else [];
}

abstract production nilBuildEventFields
top::BuildEventFields ::=
{
  propagate msgs;

  top.fieldsHandled = [];
}

--

nonterminal Exprs with location, msgs, s, types;

--propagate msgs, s on Exprs;

abstract production emptyExprs
top::Exprs ::=
{
  propagate msgs;

  top.types := [];
}

abstract production addExprs
top::Exprs ::= e::Expr rest::Exprs
{
  propagate msgs, s;

  top.types := e.type::rest.types;
}
