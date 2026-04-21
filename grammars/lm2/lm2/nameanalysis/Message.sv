grammar lm2:nameanalysis;

imports silver:langutil; -- for location.unparse

--------------------------------------------------

function err
String ::= msg::String loc::Location
{
  return loc.unparse ++ ": error: " ++ msg ++ "\n"; 
}

function warn
String ::= msg::String loc::Location
{
  return loc.unparse ++ ": warning: " ++ msg ++ "\n"; 
}



--------------------------------------------------

synthesized attribute pp::String;

fun binopOk([String], Type) ::= l::Type r::Type loc::Location 
                                 cond::(Boolean ::= Type) op::String expect::String =
  let msgs::[String] =
    if r == tErr() || cond(r)
    then []
    else [err(
      op ++ " expects type of right operand to be " ++ expect ++ ", but an expression " ++
      "was given of type " ++ r.pp,
      loc
    )]
  in
  let msgs::[String] =
    if l == tErr() || cond(l)
    then msgs
    else err(
      op ++ " expects type of left operand to be " ++ expect ++ ", but an expression " ++
      "was given of type " ++ l.pp,
      loc
    )::msgs
  in
    (msgs, if null(msgs) then castAdd(l, r) else tErr())
  end end;

fun addOk ([String], Type) ::= l::Type r::Type loc::Location =
  let ok::([String], Type) = 
    binopOk(
      l, r, loc, \t::Type -> t == tInt() || t == tFloat(), "addition", "int or float"
    )
  in
    if ok.2 == tErr() then ok else (ok.1, castAdd(l, r))
  end;

fun andOk ([String], Type) ::= l::Type r::Type loc::Location =
  binopOk(
    l, r, loc, \t::Type -> t == tBool(), "conjunction", "bool"
  );

--

fun castAdd Type ::= l::Type r::Type =
  case l, r of
  | tFloat(), _ -> tFloat()
  | _, tFloat() -> tFloat()
  | _, _        -> tInt()
  end
;

fun assert [String] ::= c::Boolean msg::String =
  if c then [] else [msg];

fun singleton Boolean ::= lst::[a] =
  length(lst) == 1;