grammar lm1:nameanalysis;

--------------------------------------------------

scope labels lex, var, mod, imp as LMLabels;

scope attribute s occurs on Decls, Decl, Module, ParBinds, Expr, Binds, Bind;
scope attribute s_last occurs on Binds;
scope attribute s_dcl occurs on Bind;
scope attribute s_module occurs on Decls, Decl, Module;
scope attribute s_def occurs on Decl, Module, ParBinds;

--------------------------------------------------

synthesized attribute errs::[String];
synthesized attribute ocaml::String;
synthesized attribute type::Type;

--------------------------------------------------

nonterminal Main with location, errs, ocaml;

abstract production program
top::Main ::= ds::Decls
{
  newScope glob;
  newScope deadScope;

  ds.s = glob;
  ds.s_module = deadScope;

  top.errs = ds.errs;

  top.ocaml = ds.ocaml;
}

--------------------------------------------------

nonterminal Decls with location, errs, ocaml;

abstract production declsCons
top::Decls ::= d::Decl ds::Decls
{
  newScope seqScope;

  seqScope -[ lex ]-> top.s;

  d.s = top.s;
  d.s_def = seqScope;
  d.s_module = top.s_module;

  ds.s = seqScope;
  ds.s_module = top.s_module;

  top.errs = d.errs ++ ds.errs;

  top.ocaml = d.ocaml ++ "\n" ++ ds.ocaml;
}

abstract production declsNil
top::Decls ::=
{
  top.errs = [];

  top.ocaml = "";
}

--------------------------------------------------

nonterminal Decl with location, errs, ocaml;

abstract production declModule
top::Decl ::= m::Module
{
  m.s = top.s;
  m.s_def = top.s_def;
  m.s_module = top.s_module;

  top.errs = m.errs;

  top.ocaml = m.ocaml;
}

abstract production declImport
top::Decl ::= mr::ModRef
{
  mr.s = top.s;
  mr.s_def = top.s_def;

  top.errs = mr.errs;

  top.ocaml = mr.ocaml;
}

abstract production declDef
top::Decl ::= b::Bind
{
  existsScope s_dcl;

  b.s = top.s;
  b.s_dcl = s_dcl;

  top.s_def -[ var ]-> s_dcl;
  top.s_module -[ var ]-> s_dcl;

  top.errs = b.errs;

  b.inSeqLet = true;

  top.ocaml = "let " ++ b.ocaml;
}

--------------------------------------------------

nonterminal Module with location, errs, ocaml;

abstract production module
top::Module ::= x::String ds::Decls
{
  newScope modScope -> datumMod(x, top);

  modScope -[ lex ]-> top.s;

  top.s_def -[ mod ]-> modScope;
  
  top.s_module -[ mod ]-> modScope;

  ds.s = modScope;
  ds.s_module = modScope;

  top.errs = ds.errs;
  top.ocaml = "module Mod_" ++ x ++ " = struct " ++
              ds.ocaml ++ "end";
}

--------------------------------------------------

nonterminal Expr with location, type, errs, ocaml;

abstract production exprVar
top::Expr ::= r::VarRef
{ 
  r.s = top.s;

  top.type = r.type;
  top.errs = r.errs;
  top.ocaml = r.ocaml;
}

abstract production exprFloat
top::Expr ::= f::Float
{
  top.type = tFloat();
  top.errs = [];
  top.ocaml = toString(f);
}

abstract production exprInt
top::Expr ::= i::Integer
{
  top.type = tInt();
  top.errs = [];
  top.ocaml = toString(i);
}

abstract production exprTrue
top::Expr ::=
{
  top.type = tBool();
  top.errs = [];
  top.ocaml = "true";
}

abstract production exprFalse
top::Expr ::=
{
  top.type = tBool();
  top.errs = [];
  top.ocaml = "false";
}

abstract production exprAdd top::Expr ::= e1::Expr e2::Expr
{ 
  e1.s = top.s;
  e2.s = top.s;
  
  local msgLeft::[String] = assert(addable(e1.type),
    err("(+) LHS type not int/float, is " ++ e1.type.pp, top.location));                     
  
  local msgRight::[String] = assert(addable(e2.type),
    err("(+) RHS type not int/float, is " ++ e2.type.pp, top.location));
  
  top.errs = msgLeft ++ msgRight ++ e1.errs ++ e2.errs;
  
  top.ocaml = "(" ++
    case e1.type, e2.type of
    | tFloat(), tFloat() -> e1.ocaml ++ " +. " ++ e2.ocaml
    | tFloat(), tInt() ->
      e1.ocaml ++ " +. (float_of_int " ++ e2.ocaml ++ ")"
    | tInt(), tFloat() ->
      "(float_of_int " ++ e1.ocaml ++ ") +. " ++ e2.ocaml
    | _, _ -> e1.ocaml ++ " + " ++ e2.ocaml
    end ++ ")";
  
  top.type = castAdd(e1.type, e2.type);
}

abstract production exprAnd
top::Expr ::= e1::Expr e2::Expr
{
  e1.s = top.s;
  nondecorated local ty1::Type = e1.type;
  
  e2.s = top.s;
  nondecorated local ty2::Type = e2.type;

  local ok::([String], Type) = andOk(ty1, ty2, top.location);

  top.errs = ok.1 ++ e1.errs ++ e2.errs;
  top.type = ok.2;

  top.ocaml = "(" ++ e1.ocaml ++ " && " ++ e2.ocaml ++ ")";
}

abstract production exprEq
top::Expr ::= e1::Expr e2::Expr
{
  e1.s = top.s;
  nondecorated local ty1::Type = e1.type;
  
  e2.s = top.s;
  nondecorated local ty2::Type = e2.type;

  local msgLeft::[String] =
    if ty1 == tInt() || ty1 == tFloat() || ty1 == tBool()
    then []
    else [err(
      "equality expects left operand to be of type int or float or bool, " ++
      "but an expression was given of type " ++ ty1.pp,
      top.location
    )];
  
  local msgRight::[String] =
    if !null(msgLeft) || ty1 == ty2
    then []
    else [err(
      "equality expects right operand to be of type " ++ ty1.pp ++ ", but an " ++
      "expression was given of type " ++ ty2.pp,
      top.location
    )];

  top.errs = if !null(msgLeft) then msgLeft else msgRight
             ++ e1.errs ++ e2.errs;
  top.type = tBool();

  top.ocaml = "(" ++ e1.ocaml ++ " = " ++ e2.ocaml ++ ")";
}

abstract production exprFun
top::Expr ::= b::Bind e::Expr
{
  existsScope s_dcl;

  newScope s_fun;

  s_fun -[ lex ]-> top.s;
  s_fun -[ var ]-> s_dcl;

  b.s = top.s;
  b.s_dcl = s_dcl;

  nondecorated local ty1::Type = b.type;

  e.s = s_fun;
  nondecorated local ty2::Type = e.type;

  top.type = tFun(ty1, ty2);

  top.errs = b.errs ++ e.errs;

  b.inSeqLet = true;
  
  top.ocaml = "(" ++ b.ocaml ++ " -> " ++ e.ocaml ++ ")"; 
}

abstract production exprApp
top::Expr ::= e1::Expr e2::Expr
{
  e1.s = top.s;
  nondecorated local ty1::Type = e1.type;
  
  e2.s = top.s;
  nondecorated local ty2::Type = e2.type;

  local ty3and4::(Boolean, Type, Type) = 
    case ty1 of
    | tFun(ty3, ty4) -> (true, ^ty3, ^ty4)
    | _ -> (false, tErr(), tErr())
    end;

  nondecorated local ty3::Type = ty3and4.2;
  nondecorated local ty4::Type = ty3and4.3;

  local msgLeft::[String] =
    if ty3and4.1
    then []
    else [err("application expects left operand to be of function type, " ++
                       "but an expression was given of type " ++ ty1.pp,
                       top.location)];

  local msgRight::[String] =
    if !null(msgLeft) || ty2 == ty3
    then []
    else [err(
      "application expects right operand to be of type " ++ ty3.pp ++ ", but an " ++
      "expression was given of type " ++ ty2.pp,
      top.location
    )];

  top.errs = e1.errs ++ e2.errs ++
              if !null(msgLeft) then msgLeft else msgRight;
  top.type = ty4;

  top.ocaml = "(" ++ e1.ocaml ++ " " ++ e2.ocaml ++ ")";
}

abstract production exprIf
top::Expr ::= e1::Expr e2::Expr e3::Expr
{
  e1.s = top.s;
  nondecorated local ty1::Type = e1.type;
  
  e2.s = top.s;
  nondecorated local ty2::Type = e2.type;

  e3.s = top.s;
  nondecorated local ty3::Type = e3.type;

  local msgs1::[String] =
    if ty1 == tBool()
    then []
    else [err(
      "conditional expects first operand to be of type bool, but an expression " ++
      "was given of type " ++ ty1.pp,
      top.location
    )];
  
  local msgs2::[String] =
    if ty2 == ty3
    then []
    else [err(
      "conditional expects else branch to be of type " ++ ty2.pp ++ ", but an expression " ++
      "was given of type " ++ ty3.pp,
      top.location
    )];

  top.type = if ty1 == tBool() && ty2 == ty3 then ty2 else tErr();

  top.errs = msgs1 ++ msgs2 ++ e1.errs ++ e2.errs ++ e3.errs;

  top.ocaml = "if " ++ e1.ocaml ++ 
                    " then " ++ e2.ocaml ++
                    " else " ++ e3.ocaml;
}

abstract production exprLet
top::Expr ::= bs::Binds e::Expr
{ 
  existsScope s_let;
  
  bs.s = top.s;
  bs.s_last = s_let; 
  
  e.s = s_let;
  
  top.errs = bs.errs ++ e.errs;
  
  top.ocaml = bs.ocaml ++ e.ocaml;
  
  top.type = e.type;
}

abstract production exprLetRec
top::Expr ::= bs::ParBinds e::Expr
{
  newScope s_let;

  s_let -[ lex ]-> top.s;

  bs.s = s_let;
  bs.s_def = s_let;

  e.s = s_let;

  top.type = e.type;

  top.errs = bs.errs ++ e.errs;

  top.ocaml = bs.ocaml ++ e.ocaml;

  bs.isFirst = true;
}

abstract production exprLetPar
top::Expr ::= bs::ParBinds e::Expr
{
  newScope s_let;

  s_let -[ lex ]-> top.s;

  bs.s = top.s;
  bs.s_def = s_let;

  e.s = s_let;

  top.type = e.type;

  top.errs = bs.errs ++ e.errs;

  top.ocaml = error("exprLetPar.ocaml TODO");

  bs.isFirst = true;
}

--------------------------------------------------

nonterminal Binds with location, errs, ocaml;

abstract production seqBindsCons
top::Binds ::= b::Bind bs::Binds
{ 
  existsScope s_dcl;
  
  newScope s_next;
  
  s_next -[ lex ]-> top.s;
  s_next -[ var ]-> s_dcl;
  
  b.inSeqLet = true;
  b.s = top.s; 
  b.s_dcl = s_dcl;
  
  bs.s = s_next;
  bs.s_last = top.s_last;
  
  top.errs = b.errs ++ bs.errs;
  
  top.ocaml = "let " ++ b.ocaml ++ " in " ++ bs.ocaml;
}

abstract production seqBindsLast
top::Binds ::= b::Bind
{ 
  
  existsScope s_dcl;
  
  newScope top.s_last;
  
  top.s_last -[ lex ]-> top.s;
  top.s_last -[ var ]-> s_dcl;
  
  b.inSeqLet = true;
  b.s = top.s;
  b.s_dcl = s_dcl; 
  
  top.errs = b.errs;
  
  top.ocaml = "let " ++ b.ocaml ++ " in ";
}

abstract production seqBindsNil
top::Binds ::=
{
  newScope top.s_last;

  top.s_last -[ lex ]-> top.s;

  top.errs = [];

  top.ocaml = "";
}

--------------------------------------------------

inherited attribute isFirst::Boolean;

nonterminal ParBinds with location, isFirst, errs, ocaml;

abstract production parBindsNil
top::ParBinds ::=
{
  top.errs = [];

  top.ocaml = "";
}

abstract production parBindsOne
top::ParBinds ::= s::Bind
{
  existsScope s_dcl;

  s.s = top.s;
  s.s_dcl = s_dcl;

  top.s_def -[ var ]-> s_dcl;

  top.errs = s.errs;

  s.inSeqLet = false;

  top.ocaml =
    (if top.isFirst then "let " else " and ") ++
    s.ocaml ++ " in ";
}

abstract production parBindsCons
top::ParBinds ::= s::Bind ss::ParBinds
{
  existsScope s_dcl;

  s.s = top.s;
  s.s_dcl = s_dcl;

  top.s_def -[ var ]-> s_dcl;

  ss.s = top.s;
  ss.s_def = top.s_def;

  top.errs = s.errs ++ ss.errs;

  s.inSeqLet = false;

  top.ocaml = 
    (if top.isFirst then "let rec " else " and ") ++
    s.ocaml ++ ss.ocaml;

  ss.isFirst = false;
}

--------------------------------------------------

inherited attribute inSeqLet::Boolean;

nonterminal Bind with location, type, inSeqLet, errs, ocaml;

abstract production bind
top::Bind ::= x::String e::Expr
{ 
  newScope top.s_dcl -> datumVar(x, top);
  
  e.s = top.s;

  top.type = e.type;
  
  top.errs = e.errs;

  top.ocaml = x ++ " = " ++ if top.inSeqLet then e.ocaml else "lazy (" ++ e.ocaml ++ ")";
}

abstract production bindTyped
top::Bind ::= tyann::Type x::String e::Expr
{
  newScope top.s_dcl -> datumVar(x, top);

  nondecorated local ty1::Type = ^tyann;
  nondecorated local ty2::Type = e.type;
  
  e.s = top.s;

  top.type = ^tyann;

  top.errs =
    if ty1 == ty2 || e.type == tErr()
    then e.errs
    else err("variable " ++ x ++ " declared with type " ++ ty1.pp ++ ", but its " ++
             "definition has type " ++ ty2.pp, top.location)::e.errs;

  top.ocaml = 
    x ++ ": " ++ tyann.ocaml ++ " = " ++ if !top.inSeqLet then "lazy (" ++ e.ocaml ++ ")" else e.ocaml;
}

abstract production bindArgDcl
top::Bind ::= x::String tyann::Type
{
  newScope top.s_dcl -> datumVar(x, top);

  top.type = ^tyann;

  top.errs = [];

  top.ocaml = "fun " ++ x ++ ":" ++ tyann.ocaml;
}

--------------------------------------------------

nonterminal Type with pp, ocaml;

abstract production tFun
top::Type ::= tyann1::Type tyann2::Type
{
  top.pp =
    case tyann1 of
    | tFun(_, _) -> "(" ++ tyann1.pp ++ ") -> " ++ tyann2.pp
    | _ -> tyann1.pp ++ " -> " ++ tyann2.pp
    end;
  
  top.ocaml =
    case tyann1 of
    | tFun(_, _) -> "(" ++ tyann1.ocaml ++ ") -> " ++ tyann2.ocaml
    | _ -> tyann1.ocaml ++ " -> " ++ tyann2.ocaml
    end;
}

abstract production tFloat
top::Type ::=
{
  top.pp = "float";
  top.ocaml = top.pp;
}

abstract production tInt
top::Type ::=
{
  top.pp = "int";
  top.ocaml = top.pp;
}

abstract production tBool
top::Type ::=
{
  top.pp = "bool";
  top.ocaml = top.pp;
}

abstract production tErr
top::Type ::=
{
  top.pp = "<err>";
  top.ocaml = error("tErr.ocaml demanded");
}

fun eqType Boolean ::= t1::Type t2::Type =
  case t1, t2 of
  | tFloat(), tFloat() -> true
  | tInt(), tInt() -> true
  | tBool(), tBool() -> true
  | tFun(t1_1, t1_2), tFun(t2_1, t2_2) -> eqType(^t1_1, ^t2_1) && eqType(^t1_2, ^t2_2)
  | tErr(), tErr() -> true
  | _, _ -> false
  end;

instance Eq Type {
  eq = eqType;
}

--------------------------------------------------

nonterminal VarRef with location, s, errs, type, ocaml;

abstract production varRef
top::VarRef ::= x::String
{
  local exact::[Decorated Scope with LMLabels] =
    query(`lex* `imp? `var,
          `var < `imp < `lex,
          isBindCalled(x), top.s);

  local close::[Decorated Scope with LMLabels] =
    query(`lex* `imp? (`var | `mod),
          `var = `mod < `imp < `lex,
          editDistanceAtMost(1, x), top.s);

  local bindNode::Decorated Bind with {s, inSeqLet} =
    if singleton(exact) then getBind(head(exact)) else defaultErrBind;

  top.errs = 
    case exact, getDclNames(close) of
    | [_], _ -> []
    | _::_, _ -> [err(x ++ " ambiguous", top.location)]
    | [], []  -> [err(x ++ " unresolvable", top.location)]
    | _, cs   -> [err(x ++ " unresolvable, close to: " ++ implode(", ", cs), top.location)]
    end;

  top.ocaml = if !bindNode.inSeqLet then "(Lazy.force " ++ x ++ ")" else x;

  top.type = bindNode.type;
}

--------------------------------------------------

nonterminal ModRef with location, s, s_def, errs, ocaml;

abstract production modRef
top::ModRef ::= x::String
{
  local mods::[Decorated Scope with LMLabels] =
    query(`lex*`imp?`mod,
          `mod < `imp < `lex,
          isModuleCalled(x), top.s);
  
  local s_res::Decorated Scope with LMLabels =
    if length(mods) == 1 then head(mods) else deadScope;

  top.s_def -[ imp ]-> s_res;

  top.errs = 
    case mods of
    | h::[] -> []
    | _::_ -> [err("ambiguous module reference " ++ x, top.location)]
    | [] -> [err("unresolvable module reference " ++ x, top.location)]
    end;

  top.ocaml = "open Mod_" ++ x;
}

--------------------------------------------------

fun getBind Decorated Bind with {s, inSeqLet} ::= s::Decorated Scope with LMLabels =
  case s.datum of
  | datumVar(_, b) -> b
  | _ -> error("Oh no!")
  end
;

fun getDclNames [String] ::= ss::[Decorated Scope with LMLabels] =
  let getDclName::(Maybe<String> ::= Decorated Scope with LMLabels) =
    \s::Decorated Scope with LMLabels ->
      case s.datum of
      | datumVar(dx, _) -> just(dx)
      | datumMod(dx, _) -> just(dx)
      | _ -> nothing()
      end
  in
    case ss of
    | [] -> []
    | s::ss -> let rest::[String] = getDclNames(ss) in
               let this::Maybe<String> = getDclName(s) in
                 if this.isJust
                 then (this.fromJust)::rest
                 else rest
               end end
    end
  end
;

global defaultErrBind::Decorated Bind with {s, inSeqLet} =
  decorate bindArgDcl("", tErr(), location=bogusLoc())
  with {s = deadScope; inSeqLet = true;};

fun isBindCalled (Boolean ::= Datum) ::= x::String =
  \d::Datum ->
    case d of
    | datumVar(dx, _) -> x == dx
    | _ -> false
    end;

fun isModuleCalled (Boolean ::= Datum) ::= x::String =
  \d::Datum ->
    case d of
    | datumMod(dx, _) -> x == dx
    | _ -> false
    end;

fun getDecoratedBind Decorated Bind with {s, inSeqLet} ::= s::Decorated Scope with LMLabels =
  case s.datum of
  | datumVar(_, n) -> n
  | _ -> error("Used extractBind on a scope not using datumVar!")
  end
;

global defaultErrorBind::Decorated Bind with {s, inSeqLet} =
  decorate bindArgDcl("", tErr(), location=bogusLoc()) with {s=deadScope; inSeqLet=true;};

fun addable Boolean ::= t::Type =
  t == tInt() || t == tFloat() || t == tErr()
;

fun editDistanceAtMost (Boolean ::= Datum) ::= i::Integer x::String =
  \d::Datum ->
    case d of
    | datumVar(dx, _) -> substring(0, i, dx) == substring(0, i, x)
    | _ -> false
    end
;