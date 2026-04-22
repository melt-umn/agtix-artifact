grammar comscan:host:analysis;

--

nonterminal EventTypeDcl with location, name, msgs, s, fields, eventTypes, parentName;
propagate msgs on EventTypeDcl;

synthesized attribute parentName::Maybe<String>;

abstract production eventTypeDcl
top::EventTypeDcl ::= name::String fields::EventFields
{ 
  top.name = name;

  newScope eventDcl -> datumEvent(top);
  eventDcl -[[ `child ]]-> query(`lex* `imp? `event, eventChildOf(name), top.s);

  fields.s = top.s;
  fields.s_def = eventDcl;

  top.s -[ `event ]-> eventDcl;

  top.eventTypes := [top];
  top.fields = fields.fields;
  top.parentName = nothing();
  top.msgs <- 
    let duplLookupRes::[Decorated Scope with CSLabels] =
      query(`lex* `imp `event, isNameDupl(name, top.location), top.s)
    in
      if !null(duplLookupRes)
      then [errMessage("duplicate event definition " ++ name ++ 
                       " - another is defined at " ++ head(duplLookupRes).datum.loc.unparse, top.location)]
      else []
    end;
}

abstract production eventTypeExtendDcl
top::EventTypeDcl ::= name::String parent::String fields::EventFields
{ 
  top.name = name;
  
  newScope eventDcl -> datumEvent(top);
  eventDcl -[ `par ]-> parAndMsgs.1;
  eventDcl -[[ `field ]]-> parAndMsgs.1.field;
  eventDcl -[[ `child ]]-> query(`lex* `imp? `event, eventChildOf(name), top.s);

  local parAndMsgs::(Decorated Scope with CSLabels, [Message]) =
    case query(`lex* `imp? `event, isName(parent), top.s) of
    | [] -> (deadScope, [errMessage("unkown event type " ++ parent, top.location)])
    | s::[] -> (s, [])
    | _ -> (deadScope, [errMessage("ambiguous event type reference " ++ parent, top.location)])
    end;

  local parFields::[(String, Type)] =
      map (\s::Decorated Scope with CSLabels -> 
              case s.datum of datumVar(node) -> (node.name, node.type) 
                            | _ -> error("eventTypeExtendDcl.fieldData") end,
           parAndMsgs.1.field);

  fields.s = top.s;
  fields.s_def = eventDcl;

  top.s -[ `event ]-> eventDcl;

  top.eventTypes := [top];
  top.fields = fields.fields ++ parFields;
  top.parentName = just(parent);
  top.msgs <- 
    let duplLookupRes::[Decorated Scope with CSLabels] =
      query(`lex* `imp? `event, isNameDupl(name, top.location), top.s)
    in
      if !null(duplLookupRes)
      then [errMessage("duplicate event definition " ++ name ++ 
                       " - another is defined at " ++ head(duplLookupRes).datum.loc.unparse, top.location)]
      else []
    end;
}

--

nonterminal EventFields with location, fields, s, s_def;
propagate s, s_def on EventFields;

abstract production nilFields
top::EventFields ::=
{ 
  top.fields = [];
}

abstract production consFields
top::EventFields ::= name::String ty::Type f2::EventFields
{
  newScope varScope -> datumVar(
    decorate dcl(^ty, name, modifiersNil(location=top.location), location=top.location)
    with { s = top.s; s_def = top.s; }
  );

  top.s_def -[ `field ]-> varScope;

  top.fields = (name, ^ty) :: f2.fields;
}
