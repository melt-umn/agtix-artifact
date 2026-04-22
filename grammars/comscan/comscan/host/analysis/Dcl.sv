grammar comscan:host:analysis;

--

inherited attribute inStateDlcs::Boolean;
synthesized attribute modsCheck::([Message] ::= Type);
monoid attribute defaultCount::Integer with 0, +;
monoid attribute defaultExpr::Maybe<Decorated Expr> with nothing(),
  \l::Maybe<Decorated Expr> r::Maybe<Decorated Expr> ->
    case l of just(_) -> l | _ -> r end;

--

nonterminal DclList with location, msgs, s, s_def;
propagate msgs, s, s_def on DclList;

abstract production branchDclList
top::DclList ::= d1::DclList d2::DclList
{
}

abstract production nilDclList
top::DclList ::=
{
}

abstract production oneDclList
top::DclList ::= d::Dcl
{
}

--

nonterminal Dcl with location, name, msgs, type, s, s_def;
propagate msgs, s on Dcl;

abstract production dcl
top::Dcl ::= ty::Type name::String mods::Modifiers
{
  top.name = name;
  top.type = ^tyWithDefault;

  newScope dclScope -> datumVar(top);
  top.s_def -[ `var ]-> dclScope;

  top.msgs <-
    if mods.defaultCount > 1
    then
      [errMessage("multiple default values given for table " ++ name, top.location)]
    else
      case ty, mods of

      | tableTy(kt, _, _), _ when !kt.indexable ->
        [errMessage("values of type " ++ kt.strRep ++ " cannot be used as table keys", top.location)]

      | tableTy(_, stringTy(), _), _ ->
        if !defaultValGiven 
        then [errMessage("tables with value type string require a default value modifier", top.location)]
        else []

      | tableTy(_, nameEventTy(n), _), _ ->
        if !defaultValGiven 
        then [errMessage("tables with value type " ++ n ++ " require a default value modifier", top.location)]
        else []

      | tableTy(_, intTy(), _), _  -> mods.modsCheck(intTy(location=bogusLoc()))
      | tableTy(_, boolTy(), _), _ -> mods.modsCheck(boolTy(location=bogusLoc()))

      | tableTy(_, vt, _), _ ->
        [errMessage("values of type " ++ vt.strRep ++ " cannot be stored in tables", top.location)]
      
      | _, _ -> []
      --| _, _ -> [errMessage("only table declarations have modifiers", top.location)]

      end;

    local defaultValGiven::Boolean = mods.defaultCount > 0;

    production attribute tyWithDefault::Type =
      case ty of
      | tableTy(kt, vt, _) ->
          tableTy(^kt, ^vt, if mods.defaultExpr.isJust
                            then mods.defaultExpr.fromJust
                            else vt.defaultExpr.fromJust,
                            location=top.location)
      | t -> ^t
      end;
}

--

nonterminal Modifiers with location, msgs, modsCheck, s, defaultCount, defaultExpr;
propagate msgs, s, defaultCount, defaultExpr on Modifiers;

abstract production modifiersCons
top::Modifiers ::= mod::Modifier mods::Modifiers
{
  top.modsCheck = \t::Type -> mod.modsCheck(t) ++ mods.modsCheck(t); 
}

abstract production modifiersOne
top::Modifiers ::= mod::Modifier
{  
  top.modsCheck = mod.modsCheck;
}

abstract production modifiersNil
top::Modifiers ::=
{
  top.modsCheck = \_ -> [];
}

--

nonterminal Modifier with location, msgs, modsCheck, s, defaultCount, defaultExpr;
propagate msgs, s on Modifier;

abstract production defaultModifier
top::Modifier ::= e::Expr
{
  top.modsCheck = \t::Type ->
    if !tyEq(t, e.type)
    then [errMessage("default expression has type " ++ e.type.strRep ++ 
                     ", but table value type is " ++ t.strRep, top.location)]
    else [];

  top.defaultCount := 1;
  top.defaultExpr := just(e);
}
