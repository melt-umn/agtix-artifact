grammar comscan:host:analysis;

--

nonterminal EventSet with location, msgs, s, type;

abstract production starEventSet
top::EventSet ::=
{
  top.type = varEventTy(location=top.location);

  top.msgs := [];
}


abstract production typesEventSet
top::EventSet ::= events::[String]
{
  top.type = multiEventTy(false, events, location=top.location);

  top.msgs := checkEventSet(events, top.s, top.location);
}


abstract production joinedEventSet
top::EventSet ::= events::[String]
{
  top.type = multiEventTy(true, events, location=top.location);

  top.msgs := checkEventSet(events, top.s, top.location);
}

--

fun checkEventSet
[Message] ::= events::[String] s::Decorated Scope with CSLabels loc::Location =
  case events of
  | [] -> []
  | h::t -> let rest::[Message] = checkEventSet(t, s, loc) in
            let lookupRes::[Decorated Scope with CSLabels] = 
                query(`lex* `imp? `event, isName(h), s) 
            in
              if length(lookupRes) < 1
              then errMessage("unresolvable event type " ++ h, loc)::rest
              else if length(lookupRes) > 1
              then errMessage("ambiguous event type " ++ h, loc)::rest
              else rest
            end end
  end;
