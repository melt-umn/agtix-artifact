grammar comscan:host:analysis;

--

synthesized attribute indexable::Boolean occurs on Type;
synthesized attribute strRep::String;
synthesized attribute defaultExprNondec::Maybe<Expr>;

--

nonterminal Type with location, s, msgs, strRep, defaultExpr, defaultExprNondec;
propagate msgs, s on Type;

--

aspect default production
top::Type ::=
{
  top.indexable = false;
  top.defaultExpr := error("defaultExpr demanded on type" ++ top.strRep);
  top.defaultExprNondec = nothing();
}

abstract production intTy
top::Type ::= 
{
  top.strRep = "int";
  top.defaultExpr := just(decorate intConst(0, location=top.location) with { s = top.s; });
  top.defaultExprNondec = just(intConst(0, location=top.location));
  top.indexable = true;
}

abstract production boolTy
top::Type ::=
{
  top.strRep = "bool";
  top.defaultExpr := just(decorate trueConst(location=top.location) with { s = top.s; });
  top.defaultExprNondec = just(trueConst(location=top.location));
  top.indexable = true;
}

abstract production tableTy
top::Type ::= key::Type value::Type dflt::Decorated Expr
{
  top.strRep = "table<" ++ key.strRep ++ ", " ++ value.strRep ++ ">";
}

abstract production stringTy
top::Type ::=
{
  top.strRep = "string";
  top.indexable = true;
}

abstract production connectionTy
top::Type ::=
{
  top.strRep = "connection";
}

-- event types

abstract production nameEventTy
top::Type ::= etype::String
{
  -- check event type is defined
  local isDefined::Boolean = 
    length(query(`lex* `imp? `event, isName(etype), top.s)) > 0;

  top.msgs <-
    if !isDefined
    then [errMessage("unknown event type " ++ etype, top.location)]
    else [];

  top.strRep = etype;
}

abstract production varEventTy
top::Type ::=
{
  top.strRep = "<varEventTy>";
}

abstract production multiEventTy
top::Type ::= hasVar::Boolean names::[String]
{
  top.strRep = "<multiEventTy: " ++ toString(hasVar) ++ 
               " - " ++ implode(", ", names) ++ ">";
}

abstract production errTy
top::Type ::=
{
  top.strRep = "<err>";
}

--

global termErrTy::Type = errTy(location=bogusLoc());

global decErrTy::Decorated Type =
  decorate termErrTy with {
    s = deadScope;
  };

--

function tyEq
Boolean ::= l::Type r::Type
{
  return
    case (l, r) of
    | (errTy(), _) -> true
    | (_, errTy()) -> true
    | (intTy(), intTy()) -> true
    | (boolTy(), boolTy()) -> true
    | (boolTy(), intTy()) -> true
    | (intTy(), boolTy()) -> true
    | (tableTy(k1, v1, _), tableTy(k2, v2, _)) -> tyEq(^k1, ^k2) && tyEq(^v1, ^v2) -- check default exprs?
    | (stringTy(), stringTy()) -> true
    | (connectionTy(), connectionTy()) -> true
    | (nameEventTy(n1), nameEventTy(n2)) -> n1 == n2
    | (varEventTy(), varEventTy()) -> true
    | (_, _) -> false
    end; 
}

function checkTypes
[Message] ::= actn::String pos::Integer loc::Location 
              expect::[Type] given::[Type]
{
  return
    case (expect, given) of
    | ([], []) -> []
    | (_::_, []) -> [ errMessage("not enough arguments given to action " ++ actn, loc) ]
    | ([], _::_) -> [ errMessage("too many argument given to action " ++ actn, loc) ]
    | (h1::t1, h2::t2) -> 
        let rest::[Message] =
          checkTypes(actn, pos + 1, loc, t1, t2)
        in
          if tyEq(h1, h2)
          then rest
          else errMessage(actn ++ " expected a value of type " ++ h1.strRep ++ 
                          " in position " ++ toString(pos) ++ 
                          " but was given a value of type " ++ h2.strRep, loc)
               ::rest
        end
    end;
}
