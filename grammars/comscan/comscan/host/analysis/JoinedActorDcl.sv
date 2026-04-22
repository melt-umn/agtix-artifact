grammar comscan:host:analysis;

--

-- scope attribute?
inherited attribute actorClassScope::Decorated Scope with CSLabels;

--

abstract production joinedActorDcl
top::ActorDcl ::= name::String params::Params a::ActorSignature
                  startInstance::String decls::InstantiateDcls
{
  top.name = name;

  top.actorDclScope = actorScope;

  newScope actorScope -> datumActor(top);
  actorScope -[ `lex ]-> top.s;


  params.s = actorScope;
  a.s = actorScope;
  decls.s = actorScope;

  top.s -[ `actor ]-> actorScope;
  
  top.connections := a.connections;
  top.hasMainActor := name == "Main";
  top.inType = a.eventSet.type;
  top.msgs <- 
    if length(query(`lex* `imp? `actor, isName(name), top.s)) > 1
    then [ errMessage("duplicate actor name " ++ name, top.location)]
    else checkMainSig(name, a.eventSet, top.connections, top.location);

  decls.parentActor = top;
}

--

inherited attribute parentActor::Decorated ActorDcl;

nonterminal InstantiateDcls with location, msgs, s, {-instEdges,-} parentActor;
propagate msgs, s, parentActor on InstantiateDcls;

abstract production nilInstantiateDcls
top::InstantiateDcls ::=
{
}

abstract production branchInstantiateDcls
top::InstantiateDcls ::= d1::InstantiateDcls d2::InstantiateDcls
{
}

abstract production oneInstantiateDcls
top::InstantiateDcls ::= d::InstantiateDcl
{
}

--

nonterminal InstantiateDcl with location, name, msgs, s, parentActor;

abstract production instantiate
top::InstantiateDcl ::= className::String actorName::String
                        initArgs::Exprs connections::ActorConnections
{
  top.name = actorName;
 
  newScope instanceScope -> datumInst(top);
  instanceScope -[ `actor ]-> classActorScope;

  local resAndMsgs::(Maybe<Decorated Scope with CSLabels>, [Message]) =
    case query(`lex* `imp? `actor, isName(className), top.s) of
    | []    -> (nothing(), [errMessage("unkown actor type " ++ className, top.location)])
    | s::[] -> (just(s), connections.msgs)
    | _     -> (nothing(), [errMessage("ambiguous actor type " ++ className, top.location)])
    end;

  local classActorScope::Decorated Scope with CSLabels = 
    if resAndMsgs.1.isJust then resAndMsgs.1.fromJust else deadScope;

  production attribute classActor::Maybe<Decorated ActorDcl> =
    case classActorScope.datum of
    | datumActor(node) -> just(node)
    | _ -> nothing()
    end;

  connections.s = top.s;
  
  connections.actorClassScope = classActorScope;
  
  top.s -[ `inst ]-> instanceScope;

  top.msgs := resAndMsgs.2; 
}

--

nonterminal ActorConnections with location, msgs, s, actorClassScope, parentActor;
propagate msgs, s, actorClassScope, parentActor on ActorConnections;

abstract production branchActorConnections
top::ActorConnections ::= c1::ActorConnections c2::ActorConnections
{
}

abstract production nilActorConnections
top::ActorConnections ::=
{
}

abstract production oneActorConnections
top::ActorConnections ::= connName::String actorName::String
{
  local subjectActorName::String =
    case top.actorClassScope.datum of
    | datumActor(node) -> node.name
    | _ -> "<err>"
    end;

  local connAndMsgs::(Decorated Scope with CSLabels, [Message]) =
    case query(`lex* `conn, isName(connName), top.actorClassScope) of
    | []    -> (deadScope, [errMessage("unkown connection type " ++ connName ++ " for actor " ++ subjectActorName, top.location)])
    | s::[] -> (s, [])
    | _     -> (deadScope, [errMessage("ambiguous connection type reference " ++ connName ++ " for actor " ++ subjectActorName, top.location)])
    end;

  -- lookup actor name (name of actor instance):

  local instAndMsgs::(Decorated Scope with CSLabels, [Message]) =
    case query((`conn | `inst), isName(actorName), top.s) of
    | []    -> (deadScope, [errMessage("unkown actor instance " ++ actorName, top.location)])
    | s::[] -> (s, [])
    | _     -> (deadScope, [errMessage("ambiguous actor instance reference " ++ actorName, top.location)])
    end;

  -- connection can be defined as a connection of the joined actor,
  -- or another locally defined instance
  local resolveClass::[Decorated Scope with CSLabels] =
    case instAndMsgs.1.datum of
    | datumConn(node) -> [instAndMsgs.1]
    | datumInst(node) -> query(`lex* `imp? `actor, any(), instAndMsgs.1)
    | _               -> []
    end;

  -- type check:

  local connType::Maybe<Type> = 
    case connAndMsgs.1.datum of
    | datumConn(node) -> just(node.type)
    | _ -> nothing()
    end;

  local actorInType::Maybe<Type> =
    case resolveClass of
    | []    -> nothing()
    | s::[] -> case s.datum of
               | datumActor(node) -> just(node.inType)
               | datumConn(node)  -> just(node.type)
               | _                -> nothing()
               end
    | _     -> nothing()
    end;

  local typesOk::Boolean =
    !connType.isJust || !actorInType.isJust ||
    let connTypeJ::Type = connType.fromJust in
    let intypeJ::Type = actorInType.fromJust in
    let inScope::Decorated Scope with CSLabels = head(resolveClass) in
      case (connTypeJ, intypeJ) of
      | (varEventTy(), multiEventTy(false, _))             -> false
      | (varEventTy(), _)                                  -> true
      | (multiEventTy(true, _), multiEventTy(false, _))    -> false
      | (multiEventTy(true, _), _)                         -> true
      | (multiEventTy(false, lst), varEventTy())           -> true
      | (multiEventTy(false, lst), multiEventTy(true, _))  -> true
      | (multiEventTy(false, lstc), multiEventTy(_, lsta)) -> 
          let lookupRes::[Decorated Scope with CSLabels] =
            -- find the scope graph declaration node for all events in lsta (list of in events for target actor)
            concat(map(\s::String -> query(`lex* `imp? `event, isName(s), inScope), 
                       lsta)) in
          let allValid::[Decorated Scope with CSLabels] =
            -- find scope graph declaration nodes for all children of the events found in the previous step
            concat(map(\s::Decorated Scope with CSLabels -> query(`child*, any(), s), lookupRes)) in
          let names::[String] = 
            -- get the names of those events
            filterMap(\s::Decorated Scope with CSLabels -> case s.datum of
                                             | datumEvent(node) -> just(node.name)
                                             | _ -> nothing()
                                             end,
                      allValid) in
          let valid::Boolean =
            -- is the target actor a good definition for the connection
            null(removeAll(names, lstc))
          in
            valid
          end end end end
      | (_, _) -> false
      end
    end end end;

  top.msgs <- connAndMsgs.2 ++ instAndMsgs.2 ++
    if !typesOk
    then [errMessage("actor instance " ++ actorName ++ " cannot be used as the " 
                      ++ connName ++ " connection of actor " ++ subjectActorName,
                     top.location)]
    else [];
}

--

fun checkMainSig
[Message] ::= actName::String inTy::EventSet conns::[(String, Type)] loc::Location
=
  if actName == "Main"
  then
    case inTy, conns of
    | starEventSet(), [(_, multiEventTy(false, ["RetCode"]))] -> []
    | _, _ -> [ errMessage("actor Main must be a joined actor with signature" ++ 
                           " * -> RetCode", loc) ]
    end
  else [];
