grammar comscan:host:analysis;

--

monoid attribute types::[Type] with [], ++;
synthesized attribute inType::Type;
-- scope attribute?
synthesized attribute actorDclScope::Decorated Scope with CSLabels;

--

nonterminal ActorDcl with location, name, inType, actorDclScope, s, connections, hasMainActor, msgs;-- actorEdges, loc;
propagate msgs on ActorDcl;

abstract production actorDcl
top::ActorDcl ::= name::String params::Params a::ActorSignature decls::ActorParts
{
  top.name = name;
  top.actorDclScope = actorScope;

  newScope actorScope -> datumActor(top);
  actorScope -[ `lex ]-> top.s;
  

  params.s = actorScope;
  params.s_def = actorScope;
  
  a.s = actorScope;

  decls.s = actorScope;
  decls.parentActor = top;

  -- checking for event coverage - i.e. for a particular event type that is
  -- specified as an input, does the actor handle it or an ancestor event type?
  local unhandledEventNames::[String] =
    -- 0. function to get the name datum of an event scope
    let getEventName::(String ::= Decorated Scope with CSLabels) = \s::Decorated Scope with CSLabels ->
      case s.datum of datumEvent(node) -> node.name
                    | _ -> error("actorDcl.unhandledEventNames 1") end
    in
    -- 1. get names of all known events (incl. imported ones)
    let allKnownEventNames::[String] = -- inherited attribute 'knownEventNames' instead?
      map(getEventName(_), query(`lex* `imp? `event, any(), top.s))
    in
    -- 2. get SG nodes of all handled events for this actor
    let handledEventScopesTrans::[Decorated Scope with CSLabels] =
      query(`lex* `handler `handles `child*, any(), actorScope)
    in
    -- 3. get names of the corresponding events from step 2
    let handledEventNamesTrans::[String] =
      map(getEventName(_), handledEventScopesTrans)
    in
    -- 4. subtract the list of handled event names from the list of all known
    let unhandledEventNames::[String] =
      removeAll(handledEventNamesTrans, allKnownEventNames)
    in
    -- 5. final list of unhandled but required events based on actor type
      case a.eventSet.type of
      | varEventTy() -> unhandledEventNames -- requires all known events handled
      | multiEventTy(true, _) -> unhandledEventNames -- requirs all known event handled
      | multiEventTy(false, lst) -> intersect(unhandledEventNames, lst) -- requires all events in lst handled
      | _ -> error("actorDcl.unhandledEventNames 2")
      end
    end end end end end;

  top.s -[ `actor ]-> actorScope;
  
  top.connections := a.connections;
  top.hasMainActor := name == "Main";
  top.inType = a.eventSet.type;
  top.msgs <-
    if length(query(`lex* `imp? `actor, isName(name), top.s)) > 1
    then [ errMessage("duplicate actor name " ++ name, top.location)]
    else if name == "Main"
    then [ errMessage("actor 'Main' must be a joined actor", top.location) ]
    else foldr(\s::String acc::[Message] ->
                 errMessage("event type " ++ s ++ " must be handled by actor " ++ name, 
                            top.location)::acc,
               [], unhandledEventNames);  
}

--

nonterminal ActorSignature with location, msgs, s, connections, eventSet;
propagate msgs, s, connections on ActorSignature;

synthesized attribute eventSet::EventSet;

abstract production actorSignature
top::ActorSignature ::= m::EventSet c::Connections
{
  top.eventSet = ^m;
}

--

nonterminal Connections with location, msgs, s, connections;
propagate msgs, s, connections on Connections;

abstract production nilConnections
top::Connections ::=
{
}

abstract production branchConnections
top::Connections ::= c1::Connections c2::Connections
{
}

abstract production basicConnection
top::Connections ::= c::Connection
{
}

--

nonterminal Connection with location, name, type, msgs, s, connections;
propagate msgs, s, connections on Connection;

abstract production connection
top::Connection ::= name::String tys::EventSet
{
  top.name = name;
  top.type = tys.type;

  newScope connScope -> datumConn(top);
  connScope -[ `lex ]-> top.s;

  top.s -[ `conn ]-> connScope;

  top.connections <- [(name, tys.type)];
}

--

nonterminal ActorParts with location, msgs, s, parentActor;
propagate msgs, s on ActorParts;

abstract production nilActorParts
top::ActorParts ::=
{
}

abstract production branchActorParts
top::ActorParts ::= d1::ActorParts d2::ActorParts
{
}

abstract production singleActorParts
top::ActorParts ::= a::ActorPart
{
}

--

nonterminal ActorPart with location, msgs, s, parentActor;
propagate msgs, s, parentActor on ActorPart;

abstract production actorState
top::ActorPart ::= sd::StateDecl
{
}

abstract production initActor
top::ActorPart ::= a::Action
{
}

abstract production actionDecl 
top::ActorPart ::= a::Action
{
}

abstract production handlerDecl
top::ActorPart ::= h::Handler
{
}

abstract production actorPartFromActorParts
top::ActorPart ::= parts::ActorParts
{
}

--

synthesized attribute paramTypes::[Type];

nonterminal Action with location, name, paramTypes, msgs, s, parentActor;
propagate msgs, parentActor on Action;

abstract production action
top::Action ::= name::String params::Params body::Stmt
{
  top.name = name;

  top.paramTypes = params.types;

  newScope actionScope -> datumAction(top);
  actionScope -[ `lex ]-> top.s;

  params.s = top.s;
  params.s_def = actionScope;

  body.s = actionScope;
  body.s_def = actionScope;

  top.s -[ `action ]-> actionScope;

  top.msgs <-
    if length(query(`lex* `action, isName(name), top.s)) > 1
    then [errMessage("duplicate action definition " ++ name, top.location)]
    else [];
}

abstract production init
top::Action ::= body::Stmt
{
  top.name = "#_" ++ parentActorName ++ "_init";

  top.paramTypes = [];
  
  local parentActorName::String = 
    case top.s.datum of
    | datumActor(node) -> node.name
    | _ -> "<err>"
    end;

  newScope initScope -> datumAction(top);
  initScope -[ `lex ]-> top.s;

  body.s = initScope;
  body.s_def = initScope;
}

--

nonterminal Handler with location, name, msgs, s, parentActor;
propagate msgs, parentActor on Handler;

production handler
top::Handler ::= eventId::String paramId::String body::Stmt
{
  top.name = genName;

  local genName::String = "@_" ++ parentActorInfo.1 ++ "_" ++ eventId;

  local eventType::Type = nameEventTy(eventId, location=top.location);
  eventType.s = top.s;
  
  local parentActorInfo::(String, Type) = 
    case top.s.datum of
    | datumActor(node) -> (node.name, node.inType)
    | _ -> ("<err>", termErrTy)
    end;

  local handlerSubjectOkMsgs::[Message] =
    case parentActorInfo.2 of
    | varEventTy()             -> [] -- any event handleable
    | multiEventTy(true, _)    -> [] -- any event handleable
    | multiEventTy(false, lst) ->
        let specifiedEvents::[Decorated Scope with CSLabels] = -- resolve names of all events the actor says it takes in
          concat(map(\e::String -> query(`lex* `imp? `event, isName(e), top.s), lst)) in
        let foundEvent::[Decorated Scope with CSLabels] =      -- get targets of CHILD edges of the scope of those events
          concat(map(\s::Decorated Scope with CSLabels -> query(`child*, isName(eventId), s), specifiedEvents))
        in
          case foundEvent of
          | []    -> [errMessage("actor cannot handle event type " ++ eventId, top.location)]
          | s::[] -> []
          | _     -> [] -- not giving ambiguity error here because event sig can be M1|M2 where M2 is a child of M1
          end
        end end
    | _ -> error("handlerSubjectOkMsgs")
    end;

  local eventScope::Maybe<Decorated Scope with CSLabels> = 
    case query(`lex* `imp? `event, isName(eventId), top.s) of
    | []    -> nothing()
    | s::[] -> just(s)
    | _     -> nothing()
    end;

  newScope handlerScope -> datumHandler(top);
  handlerScope -[ `lex ]-> top.s;
  handlerScope -[ `var ]-> paramScope;
  handlerScope -[ `handles ]-> if eventScope.isJust then eventScope.fromJust else deadScope;

  newScope paramScope -> datumVar(
    decorate dcl(
      ^eventType,
      paramId,
      modifiersNil(location=top.location),
      location=top.location
    ) with { s = top.s; s_def = top.s; }
  );

  body.s = handlerScope;
  body.s_def = handlerScope;

  top.s -[ `handler ]-> handlerScope;

  top.msgs <- 
    if !null(eventType.msgs)
    then eventType.msgs
    else if !null(handlerSubjectOkMsgs)
    then handlerSubjectOkMsgs
    else if length(query(`lex* `action, isName(genName), top.s)) > 1
    then [errMessage("duplicate handler definition for event type " ++ eventId, top.location)]
    else [];

}

--

nonterminal StateDecl with location, msgs, s;
propagate msgs, s on StateDecl;

abstract production state
top::StateDecl ::= d::DclList
{
  d.s_def = top.s;
}

--

nonterminal Params with location, s, s_def, msgs, types;
propagate msgs, s, s_def on Params;
propagate types on Params excluding oneParams;

abstract production branchParams
top::Params ::= p1::Params p2::Params
{
}

abstract production nilParams
top::Params ::=
{
}

abstract production oneParams
top::Params ::= ty::Type name::String
{
  newScope paramScope -> datumVar(
    decorate dcl(
      ^ty, name,
      modifiersNil(location=top.location),
      location=top.location
    ) with { s = top.s; s_def = top.s; }
  );

  top.s_def -[ `var ]-> paramScope;

  top.types := [^ty];
  top.msgs <-
    if length(query(`lex* `var, isName(name), top.s)) > 1
    then [errMessage("duplicate parameter name " ++ name, top.location)]
    else [];  
}
