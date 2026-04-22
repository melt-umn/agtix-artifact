grammar comscan:host:analysis;

--

nonterminal Stmt with location, msgs, s, s_def, parentActor;
--propagate msgs, parentActor on Stmt;

aspect default production
top::Stmt ::= 
{
  propagate msgs;
}

abstract production dclStmt
top::Stmt ::= d::DclList
{
  propagate s, s_def, msgs;
}

abstract production assign
top::Stmt ::= lhs::LHS e::Expr
{ 
  propagate s, msgs;

  local expectType::Type = lhs.type;
  local exprType::Type = e.type;

  top.msgs <-
    if !tyEq(^expectType, ^exprType)
    then [ errMessage("assignment expected an expression of type " ++ 
                      expectType.strRep ++ ", but an expression of type " ++
                      exprType.strRep ++ " was given", top.location) ]
    else [];
}

abstract production ifThenElse
top::Stmt ::= cond::Expr th::Stmt el::Stmt
{
  propagate s, msgs;

  top.msgs <-
    if !tyEq(cond.type, boolTy(location=bogusLoc()))
    then [ errMessage("condition of an if statement must have type bool",
                      top.location) ]
    else [];
}

abstract production send
top::Stmt ::= event::Expr connection::String
{
  propagate s, msgs;

  local connRes::[Decorated Scope with CSLabels] =
    query(`lex* `conn, isName(connection), top.s);

  local eventListM::Maybe<[String]> = 
    case connRes of
    | s::_ ->
      case s.datum of
      | datumConn(node) ->
          case node.type of
          | varEventTy() -> nothing()
          | multiEventTy(true, _) -> nothing()
          | multiEventTy(false, lst) -> just(lst)
          | _ -> error("send.eventListM 1")
          end
      | _ -> error("send.eventListM 2")
      end
    | _ -> error("send.eventListM 3")
    end;

  local eventName::Maybe<String> =
    case event.type of
    | nameEventTy(n) -> just(n)
    | _ -> nothing()
    end;

  local resolveConnectionScopes::[Decorated Scope with CSLabels] =
    if eventListM.isJust && eventName.isJust then
      foldr(
        \c::String acc::[Decorated Scope with CSLabels] ->
          if null(acc) then
            let res::[Decorated Scope with CSLabels] = query(`lex* `imp? `event, isName(c), top.s)
            in
            let ch::[Decorated Scope with CSLabels] = 
              concat(map(\s::Decorated Scope with CSLabels ->
                            query(`child*, isName(eventName.fromJust), s),
                        res)) 
            in
              ch
            end end
          else
            acc,
        [],
        eventListM.fromJust
      )
    else [];

  top.msgs <-
    if length(connRes) < 1
    then [ errMessage("unresolvable connection reference " ++ connection, top.location) ]
    else if length(connRes) > 1
    then [ errMessage("ambiguous connection reference " ++ connection, top.location) ]
    else if !eventName.isJust
    then [ errMessage("send to " ++ connection ++ " expected an event, " ++ 
                      "but got an expression of type " ++ 
                      event.type.strRep, top.location) ]
    else if !null(connRes) && eventName.isJust && length(resolveConnectionScopes) < 1
    then [ errMessage("cannot send event of type " ++ event.type.strRep ++
                      " to connection " ++ connection, top.location) ]
    else [];
}

abstract production removeEntry
top::Stmt ::= idx::Expr table::Expr
{
  propagate s, msgs;

  top.msgs <- 
    case idx.type, table.type of
    | t1, tableTy(kt, _, _) when tyEq(t1, ^kt) -> []
    | t1, tableTy(kt, _, _) ->
      [ errMessage("remove entry expected a key of type " ++ kt.strRep ++
                   " but received an expression of type " ++ t1.strRep, 
                   top.location) ]
    | _, _ ->
      [ errMessage("right operand expected a table but received an expression " ++
                   "of type " ++ table.type.strRep, top.location) ]
    end;
}

abstract production callAction
top::Stmt ::= act::String args::Exprs
{
  propagate s, msgs;

  local result::[Decorated Scope with CSLabels] = query(`lex* `action, isName(act), top.s);

  local paramTypes::[Type] = 
    case head(result).datum of
    | datumAction(node) -> node.paramTypes
    | _ -> error("callAction.paramTypes")
    end;

  local exprTypes::[Type] = args.types;

  top.msgs <- 
    if length(result) < 1
      then [ errMessage("could not resolve action " ++ act, top.location) ]
    else if length(result) > 1 
      then [ errMessage("ambiguous action " ++ act, top.location) ]
    else checkTypes(act, 1, top.location, paramTypes, exprTypes);
}

abstract production matchEventTy
top::Stmt ::= event::String clauses::Clauses
{
  propagate s, msgs;

  clauses.matchName = event;
}

abstract production noop
top::Stmt ::=
{
  propagate msgs;
}

abstract production seq
top::Stmt ::= s1::Stmt s2::Stmt
{
  propagate msgs;
  
  newScope seqScope;
  seqScope -[ `lex ]-> top.s;

  s1.s = top.s;
  s1.s_def = seqScope;

  s2.s = seqScope;
  s2.s_def = seqScope;
}


abstract production printStmt
top::Stmt ::= e::Expr
{
  propagate s;

  top.msgs <-
    if !tyEq(e.type, stringTy(location=bogusLoc()))
    then [ errMessage("print statement expects an expression of type string, " ++ 
                      "but an expression of type " ++ e.type.strRep ++ " was given",
                      top.location) ]
    else [];
}

--

inherited attribute matchName::String;

nonterminal Clauses with location, msgs, s, matchName, parentActor;
--propagate msgs, matchName, parentActor on Clauses;

abstract production consClauses
top::Clauses ::= c::Clause cs::Clauses
{
  propagate msgs, matchName, parentActor, s;
}

abstract production defaultClauses
top::Clauses ::= s::Stmt
{
  propagate msgs, matchName, parentActor, s;
}

abstract production nilClauses
top::Clauses ::=
{
  propagate msgs, matchName, parentActor;
}

--

nonterminal Clause with location, msgs, s, matchName, parentActor;
--propagate msgs, parentActor on Clause;

abstract production oneClause
top::Clause ::= ety::String st::Stmt
{
  propagate msgs, parentActor;

  st.s = top.s;
  st.s_def = top.s;

  newScope varScope -> datumVar(
    decorate dcl(
      nameEventTy(ety, location=top.location),
      top.matchName,
      modifiersNil(location=top.location),
      location=top.location
    )
    with { s = top.s; s_def = top.s; }
  );

  newScope clauseScope;
  clauseScope -[ `lex ]-> top.s;
  clauseScope -[ `var ]-> varScope;
}

--

nonterminal LHS with location, msgs, s, type, resScope;
--propagate msgs, scope on LHS;

synthesized attribute resScope::Maybe<Decorated Scope with CSLabels>;

abstract production nameLHS
top::LHS ::= name::String
{
  propagate msgs, s;

  local result::[Decorated Scope with CSLabels] = 
    query(`lex* `var, isName(name), top.s);

  local tyEventScopeTuple::(Type, Maybe<Decorated Scope with CSLabels>) =
    case result of
    | s::_ ->
        case s.datum of
        | datumVar(node) ->
            case node.type of
            | nameEventTy(n) ->
                let t_::Type = nameEventTy(n, location=top.location) in
                let res::[Decorated Scope with CSLabels] = query(`lex* `imp? `event, isName(n), top.s)
                in if !null(res)
                  then (t_, just(head(res)))
                  else (termErrTy, nothing())
                end end
            | _ -> (node.type, nothing())
            end
        | _ -> (termErrTy, nothing())
        end
    | _ -> (termErrTy, nothing())
    end;

  top.type = tyEventScopeTuple.1;

  top.msgs <- 
    if length(result) < 1
      then [ errMessage("could not resolve name " ++ name, top.location) ]
    else if length(result) > 1 
      then [ errMessage("ambiguous name " ++ name, top.location) ]
    else [];

  top.resScope = tyEventScopeTuple.2;
}


abstract production indexLHS
top::LHS ::= table::LHS idx::Expr
{
  propagate msgs, s;

  top.resScope = nothing();

  top.type =
    case table.type of
    | tableTy(kt, vt, _) -> ^vt
    | _ -> termErrTy
    end;

  top.msgs <-
    case idx.type, table.type of
    | t1, tableTy(kt, _, _) when tyEq(t1, ^kt) -> []
    | t1, tableTy(kt, _, _) ->
      [ errMessage("index expected a key of type " ++ kt.strRep ++
                   " but received an expression of type " ++ t1.strRep, 
                   top.location) ]
    | _, _ ->
      [ errMessage("index expected a table but received an LHS " ++
                   "of type " ++ table.type.strRep, top.location) ]
    end;
}


abstract production recFieldLHS
top::LHS ::= rec::LHS field::String
{
  propagate msgs, s;

  local result::[Decorated Scope with CSLabels] = 
    case rec.resScope of
    | just(s) -> query(`field, isName(field), s)
    | _ -> []
    end;

  top.type = case result of
             | s::_ ->
                case s.datum of
                | datumVar(node) -> node.type
                | _ -> termErrTy
                end
             | _ -> termErrTy
             end;

  top.msgs <- 
    if length(result) < 1
      then [ errMessage("could not resolve field " ++ field, top.location) ]
    else if length(result) > 1 
      then [ errMessage("ambiguous field " ++ field, top.location) ]
    else [];

  top.resScope = nothing();
}
