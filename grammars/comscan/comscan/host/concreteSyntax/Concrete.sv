grammar comscan:host:concreteSyntax;

--

synthesized attribute ast<a>::a;

closed nonterminal File_c with ast<File>, location;


concrete productions top::File_c
| d::TopDcls_c
  { top.ast = file(d.ast, location=top.location); }


closed nonterminal TopDcls_c with ast<TopDcls>, location;
closed nonterminal TopDcl_c  with ast<TopDcls>, location;


concrete productions top::TopDcls_c
|
  { top.ast = nilTopDcls(location=top.location); }
| d::TopDcl_c rest::TopDcls_c
  { top.ast = branchTopDcls(d.ast, rest.ast, location=top.location); }

concrete productions top::TopDcl_c
| d::ActorDcl_c
  { top.ast = actorTopDcls(d.ast, location=top.location); }
| d::EventTypeDcl_c
  { top.ast = eventTypeTopDcls(d.ast, location=top.location); }
| 'import' filename::Filename_t ';'
  { top.ast = importTopDcls(substring(1, length(filename.lexeme) - 1,
                                      filename.lexeme),
                            location=top.location); }

closed nonterminal EventTypeDcl_c with ast<EventTypeDcl>, location;
closed nonterminal EventFields_c  with ast<EventFields>, location;

concrete productions top::EventTypeDcl_c
| Event_t name::Id_t '{' fields::EventFields_c '}' ';'
  { top.ast = eventTypeDcl(name.lexeme, 
                           fields.ast, location=top.location); }
| Event_t name::Id_t 'extends' parent::Id_t 
  'with' '{' fields::EventFields_c '}' ';'
  { top.ast = eventTypeExtendDcl(name.lexeme, 
                                 parent.lexeme, fields.ast, 
                                 location=top.location); }

concrete productions top::EventFields_c
| 
  { top.ast = nilFields(location=top.location); }
| ty::Type_c field::Id_t ';' rest::EventFields_c
  { top.ast = consFields(field.lexeme, ty.ast, rest.ast, location=top.location); }


closed nonterminal InstantiateDcl_c with ast<InstantiateDcl>, location;

concrete productions top::InstantiateDcl_c
| actorClassName::Id_t actorName::Id_t
  'with' '{' c::ActorConnections_c '}' ';'
  { top.ast = instantiate(actorClassName.lexeme, actorName.lexeme,
                          emptyExprs(location=top.location), c.ast,
                          location=top.location); }
| actorClassName::Id_t actorName::Id_t '(' ')'
  'with' '{' c::ActorConnections_c '}' ';'
  { top.ast = instantiate(actorClassName.lexeme, actorName.lexeme,
                          emptyExprs(location=top.location), c.ast,
                          location=top.location); }
| actorClassName::Id_t actorName::Id_t
  '(' e::Exprs_c ')'
  'with' '{' c::ActorConnections_c '}' ';'
  { top.ast = instantiate(actorClassName.lexeme, actorName.lexeme,
                          e.ast, c.ast, location=top.location); }


closed nonterminal InstantiateDcls_c with ast<InstantiateDcls>, location;

concrete productions top::InstantiateDcls_c
| d::InstantiateDcl_c
  { top.ast = oneInstantiateDcls(d.ast, location=top.location); }
| d::InstantiateDcl_c rest::InstantiateDcls_c
  { top.ast = branchInstantiateDcls(
                 oneInstantiateDcls(d.ast, location=d.location),
                 rest.ast, location=top.location); }


closed nonterminal ActorConnections_c with ast<ActorConnections>, location;

concrete productions top::ActorConnections_c
|
  { top.ast = nilActorConnections(location=top.location); }
| connection::Id_t '=' actorName::Id_t ',' rest::ActorConnections_c
  { top.ast = branchActorConnections(
                 oneActorConnections(connection.lexeme,
                                     actorName.lexeme,
                                     location=connection.location),
                 rest.ast, location=top.location); }
| connection::Id_t '=' actorName::Id_t
  { top.ast = oneActorConnections(connection.lexeme,
                                     actorName.lexeme,
                                     location=connection.location); }



closed nonterminal ActorDcl_c with ast<ActorDcl>, location;
closed nonterminal ActorSignature_c with ast<ActorSignature>, location;
closed nonterminal ActorKinds_c with ast<Connections>, location;
closed nonterminal EventSet_c with ast<EventSet>, location;
closed nonterminal Events_c with ast<[String]>, hasVar, location;

synthesized attribute hasVar::Boolean;


concrete productions top::ActorDcl_c
-- "regular" actor
| 'actor' name::Id_t p::MaybeJoinedActorArgs_c ':' s::ActorSignature_c '{'
     body::ActorParts_c
  '}'
  { top.ast = actorDcl(name.lexeme, p.ast, s.ast, body.ast,
                       location=top.location); }
-- joined actor
| 'actor' name::Id_t p::MaybeJoinedActorArgs_c ':'
   s::ActorSignature_c ';' 'start' '=' a::Id_t '{'
     body::InstantiateDcls_c
  '}'
  { top.ast = joinedActorDcl(name.lexeme, p.ast, s.ast, 
                             a.lexeme, body.ast,
                             location=top.location); }


closed nonterminal MaybeJoinedActorArgs_c with ast<Params>, location;

concrete productions top::MaybeJoinedActorArgs_c
| '(' ')'
  { top.ast = nilParams(location=top.location); }
| '(' args::ArgumentList_c ')'
  { top.ast = args.ast; }


concrete productions top::ActorSignature_c
| m::EventSet_c '->' kinds::ActorKinds_c
  { top.ast = actorSignature(m.ast, kinds.ast,
                             location=top.location); }
| m::EventSet_c '->'
  { top.ast = actorSignature(m.ast,
                 nilConnections(location=top.location),
                 location=top.location); }


concrete productions top::ActorKinds_c
| conn::Id_t ':' e::EventSet_c
  { top.ast =
        basicConnection(connection(conn.lexeme, e.ast, location=top.location), location=top.location); }
| conn::Id_t ':' e::EventSet_c ',' rest::ActorKinds_c
  { top.ast =
        branchConnections(
           basicConnection(connection(conn.lexeme, e.ast, location=top.location), location=top.location),
           rest.ast, location=top.location); }


concrete productions top::EventSet_c
| events::Events_c
  { top.ast =
        if events.hasVar
        then if null(events.ast)
             then starEventSet(location=top.location)
             else joinedEventSet(events.ast, location=top.location)
        else typesEventSet(events.ast, location=top.location); }


concrete productions top::Events_c
| '*'
  { top.ast = []; top.hasVar = true; }
| name::Id_t
  { top.ast = [name.lexeme]; top.hasVar = false; }
| '*' '|' rest::Events_c
  { top.ast = rest.ast; top.hasVar = true; }
| name::Id_t '|' rest::Events_c
  { top.ast = name.lexeme::rest.ast;  top.hasVar = rest.hasVar; }


closed nonterminal ActorParts_c with ast<ActorParts>, location;
closed nonterminal ActorPart_c with ast<ActorPart>, location;


concrete productions top::ActorParts_c
|
  { top.ast = nilActorParts(location=top.location); }
| a::ActorPart_c rest::ActorParts_c
  { top.ast = branchActorParts(
                 singleActorParts(a.ast, location=top.location),
                 rest.ast, location=top.location); }


concrete productions top::ActorPart_c
| s::StateDecl_c
  { top.ast = actorState(s.ast, location=top.location); }
| 'init' '{' body::StatementList_c '}'
  { top.ast = initActor(init(body.ast, location=top.location), location=top.location); }
--general actions
| 'action' name::Id_t '(' a::ArgumentList_c ')'
  '{' body::StatementList_c '}'
  { top.ast = actionDecl(action(name.lexeme, a.ast, body.ast, location=top.location),
                         location=top.location); }
| 'action' name::Id_t '(' ')' '{' body::StatementList_c '}'
  { top.ast =
        actionDecl(action(name.lexeme, nilParams(location=top.location), body.ast, location=top.location),
                   location=top.location); }
| 'handler' ety::Id_t '(' name::Id_t ')' 
  '{' body::StatementList_c '}'
  { top.ast = handlerDecl(handler(ety.lexeme, name.lexeme, body.ast, location=top.location),
                          location=top.location); }


closed nonterminal StateDecl_c with ast<StateDecl>, location;


concrete productions top::StateDecl_c
| 'control' '{' d::DeclarationList_c '}'
  { top.ast = state(d.ast, location=top.location); }


closed nonterminal ArgumentList_c with ast<Params>, location;


concrete productions top::ArgumentList_c
| ty::Type_c name::Id_t
  { top.ast = oneParams(ty.ast, name.lexeme, location=top.location); }
| ty::Type_c name::Id_t ',' rest::ArgumentList_c
  { top.ast = branchParams(oneParams(ty.ast, name.lexeme,
                                     location=top.location),
                           rest.ast, location=top.location); }



closed nonterminal Declaration_c with ast<DclList>, location;
closed nonterminal DeclarationList_c with ast<DclList>, location;
closed nonterminal Type_c with ast<Type>, location;


concrete productions top::DeclarationList_c
|
  { top.ast = nilDclList(location=top.location); }
| d::Declaration_c rest::DeclarationList_c
  { top.ast = branchDclList(d.ast, rest.ast, location=top.location); }


concrete production declWithMods_c
top::Declaration_c ::= ty::Type_c name::Id_t mods::Modifiers_c ';'
  { top.ast = oneDclList(dcl(ty.ast, name.lexeme, mods.ast, location=top.location), location=top.location); }

concrete production declNoMods_c
top::Declaration_c ::= ty::Type_c name::Id_t ';'
{ top.ast = oneDclList(dcl(ty.ast, name.lexeme, modifiersNil(location=top.location), location=top.location), location=top.location); }


closed nonterminal Modifiers_c with ast<Modifiers>, location;

concrete production modifiersCons_c
top::Modifiers_c ::= mod::Modifier_c ',' mods::Modifiers_c
{ top.ast = modifiersCons(mod.ast, mods.ast, location=top.location); }
concrete production modifiersOne_c
top::Modifiers_c ::= mod::Modifier_c
{ top.ast = modifiersOne(mod.ast, location=top.location); }


closed nonterminal Modifier_c with ast<Modifier>, location;

concrete production defaultModifier_c
top::Modifier_c ::= 'default' e::Expr_c
{ top.ast = defaultModifier(e.ast, location=top.location); }


concrete productions top::Type_c
| 'table' '<' keyTy::Type_c ',' valueTy::Type_c '>'
  { top.ast = tableTy(keyTy.ast, valueTy.ast, 
                      error("table default demanded when it shouldn't have been"),
                      location=top.location); }
| 'int'
  { top.ast = intTy(location=top.location); }
| 'bool'
  { top.ast = boolTy(location=top.location); }
| 'string'
  { top.ast = stringTy(location=top.location); }
| ety::Id_t
  { top.ast = nameEventTy(ety.lexeme, location=top.location); }


closed nonterminal StatementList_c with ast<Stmt>, location;
closed nonterminal Statement_c with ast<Stmt>, location;
closed nonterminal MatchedIfStmt_c with ast<Stmt>, location;
closed nonterminal UnmatchedIfStmt_c with ast<Stmt>, location;
closed nonterminal Clauses_c with ast<Clauses>, location;
closed nonterminal AssignmentSymbol_c with ast<(Stmt ::= LHS Expr)>, location;
closed nonterminal LHS_c with ast<LHS>, location;

concrete productions top::StatementList_c
|
  { top.ast = noop(location=top.location); }
| s::Statement_c rest::StatementList_c
  { top.ast = seq(s.ast, rest.ast, location=top.location); }


concrete productions top::Statement_c
| s::MatchedIfStmt_c
  { top.ast = s.ast; }
| s::UnmatchedIfStmt_c
  { top.ast = s.ast; }


concrete productions top::UnmatchedIfStmt_c
| 'if' cond::Expr_c th::Statement_c
  { top.ast = ifThenElse(cond.ast, th.ast, noop(location=top.location),
                         location=top.location); }
| 'if' cond::Expr_c th::MatchedIfStmt_c 'else' el::UnmatchedIfStmt_c
  { top.ast = ifThenElse(cond.ast, th.ast, el.ast,
                         location=top.location); }


concrete productions top::MatchedIfStmt_c

| 'if' cond::Expr_c th::MatchedIfStmt_c 'else' el::MatchedIfStmt_c
  { top.ast = ifThenElse(cond.ast, th.ast, el.ast,
                         location=top.location); }

| d::Declaration_c
  { top.ast = dclStmt(d.ast, location=top.location); }

| lhs::LHS_c a::AssignmentSymbol_c e::Expr_c ';'
  { top.ast = a.ast(lhs.ast, e.ast); }

| Send_t event::Expr_c To_t conn::Id_t ';'
  { top.ast = send(event.ast, conn.lexeme, location=top.location); }

| 'remove' i::Expr_c 'from' table::Expr_c ';'
  { top.ast = removeEntry(i.ast, table.ast, location=top.location); }

| 'match' 'type' '(' name::Id_t ')'
  'with' clauses::Clauses_c 'end' ';'
  { top.ast = matchEventTy(name.lexeme, clauses.ast,
                           location=top.location); }
| actnName::Id_t '(' ')' ';'
  { top.ast =
      callAction(actnName.lexeme, emptyExprs(location=top.location),
                 location=top.location); }

| actnName::Id_t '(' e::Exprs_c ')' ';'
  { top.ast = callAction(actnName.lexeme, e.ast, location=top.location); }

| '{' s::StatementList_c '}'
  { top.ast = s.ast; }

| 'print' '(' e::Expr_c ')' ';'
  {  top.ast = printStmt(e.ast, location=top.location); }

concrete productions top::Clauses_c
| '|' mty::Id_t '->' s::Statement_c
  { top.ast = consClauses(
                oneClause(mty.lexeme, s.ast, location=top.location), 
                nilClauses(location=top.location), location=top.location); }
| '|' mty::Id_t '->' s::Statement_c rest::Clauses_c
  { top.ast = consClauses(
                 oneClause(mty.lexeme, s.ast, location=top.location),
                 rest.ast, location=top.location); }


concrete productions top::AssignmentSymbol_c
| '='
  { top.ast = assign(_, _, location=top.location); }


concrete productions top::LHS_c
| name::Id_t
  { top.ast = nameLHS(name.lexeme, location=top.location); }
| l::LHS_c '[' e::Expr_c ']'
  { top.ast = indexLHS(l.ast, e.ast, location=top.location); }
| l::LHS_c '.' field::Id_t
  { top.ast = recFieldLHS(l.ast, field.lexeme,
                          location=top.location); }



closed nonterminal Expr_c with ast<Expr>, location;
closed nonterminal BoolOrExpr_c with ast<Expr>, location;
closed nonterminal BoolAndExpr_c with ast<Expr>, location;
closed nonterminal BitOrExpr_c with ast<Expr>, location;
closed nonterminal BitAndExpr_c with ast<Expr>, location;
closed nonterminal CompExpr_c with ast<Expr>, location;
closed nonterminal ShiftExpr_c with ast<Expr>, location;
closed nonterminal AppendExpr_c with ast<Expr>, location;
closed nonterminal AddExpr_c with ast<Expr>, location;
closed nonterminal MultExpr_c with ast<Expr>, location;
closed nonterminal UnaryExpr_c with ast<Expr>, location;
closed nonterminal FactorExpr_c with ast<Expr>, location;
closed nonterminal BuildEventFields_c with ast<BuildEventFields>, location;
closed nonterminal Exprs_c with ast<Exprs>, location;


concrete productions top::Expr_c
| e::BoolOrExpr_c
  { top.ast = e.ast; }


concrete productions top::BoolOrExpr_c
| e1::BoolOrExpr_c '||' e2::BoolAndExpr_c
  { top.ast = boolOr(e1.ast, e2.ast, location=top.location); }
| e::BoolAndExpr_c
  { top.ast = e.ast; }


concrete productions top::BoolAndExpr_c
| e1::BoolAndExpr_c '&&' e2::BitOrExpr_c
  { top.ast = boolAnd(e1.ast, e2.ast, location=top.location); }
| e::BitOrExpr_c
  { top.ast = e.ast; }


concrete productions top::BitOrExpr_c
| e1::BitOrExpr_c '|' e2::BitAndExpr_c
  { top.ast = bitOr(e1.ast, e2.ast, location=top.location); }
| e::BitAndExpr_c
  { top.ast = e.ast; }


concrete productions top::BitAndExpr_c
| e1::BitAndExpr_c '&' e2::CompExpr_c
  { top.ast = bitAnd(e1.ast, e2.ast, location=top.location); }
| e::CompExpr_c
  { top.ast = e.ast; }


concrete productions top::CompExpr_c
| e1::CompExpr_c '==' e2::ShiftExpr_c
  { top.ast = eqComp(e1.ast, e2.ast, location=top.location); }
| e1::CompExpr_c '!=' e2::ShiftExpr_c
  { top.ast = neqComp(e1.ast, e2.ast, location=top.location); }
| e1::CompExpr_c '>' e2::ShiftExpr_c
  { top.ast = gtComp(e1.ast, e2.ast, location=top.location); }
| e1::CompExpr_c '<' e2::ShiftExpr_c
  { top.ast = ltComp(e1.ast, e2.ast, location=top.location); }
| e1::CompExpr_c '>=' e2::ShiftExpr_c
  { top.ast = geComp(e1.ast, e2.ast, location=top.location); }
| e1::CompExpr_c '<=' e2::ShiftExpr_c
  { top.ast = leComp(e1.ast, e2.ast, location=top.location); }
| e::ShiftExpr_c
  { top.ast = e.ast; }


concrete productions top::ShiftExpr_c
| e1::ShiftExpr_c '<<' e2::AppendExpr_c
  { top.ast = lshift(e1.ast, e2.ast, location=top.location); }
| e1::ShiftExpr_c '>>' e2::AppendExpr_c
  { top.ast = rshift(e1.ast, e2.ast, location=top.location); }
| e::AppendExpr_c
  { top.ast = e.ast; }

concrete productions top::AppendExpr_c
| e1::AppendExpr_c '++' e2::AddExpr_c
  { top.ast = append(e1.ast, e2.ast, location=top.location); }
| e::AddExpr_c
  { top.ast = e.ast; }


concrete productions top::AddExpr_c
| e1::AddExpr_c '+' e2::MultExpr_c
  { top.ast = plus(e1.ast, e2.ast, location=top.location); }
| e1::AddExpr_c '-' e2::MultExpr_c
  { top.ast = minus(e1.ast, e2.ast, location=top.location); }
| e::MultExpr_c
  { top.ast = e.ast; }


concrete productions top::MultExpr_c
| e1::MultExpr_c '*' e2::UnaryExpr_c
  { top.ast = mult(e1.ast, e2.ast, location=top.location); }
| e1::MultExpr_c '%' e2::UnaryExpr_c
  { top.ast = mod(e1.ast, e2.ast, location=top.location); }
| e::UnaryExpr_c
  { top.ast = e.ast; }


concrete productions top::UnaryExpr_c
| '~' e::UnaryExpr_c
  { top.ast = bitNeg(e.ast, location=top.location); }
| '-' e::UnaryExpr_c
  { top.ast = numNeg(e.ast, location=top.location); }
| '!' e::UnaryExpr_c
  { top.ast = boolNeg(e.ast, location=top.location); }
| e::FactorExpr_c
  { top.ast = e.ast; }


concrete productions top::FactorExpr_c
| name::Id_t
  { top.ast = var(name.lexeme, location=top.location); }
| num::Int_t
  { top.ast = intConst(toInteger(num.lexeme), location=top.location); }
| 'true'
  { top.ast = trueConst(location=top.location); }
| 'false'
  {top.ast = falseConst(location=top.location); }
| str::String_t
  { top.ast = stringConst(substring(1, length(str.lexeme)-1, str.lexeme), 
                          location=top.location); }
| table::FactorExpr_c '[' idx::Expr_c ']'
  { top.ast = index(table.ast, idx.ast, location=top.location); }
| record::FactorExpr_c '.' field::Id_t
  { top.ast = fieldAccess(record.ast, field.lexeme,
                          location=top.location); }
| ety::Id_t 'with' '{' fields::BuildEventFields_c '}'
  { top.ast = eventBuild(ety.lexeme, fields.ast,
                           location=top.location); }
| '(' e::Expr_c ')'
  { top.ast = e.ast; }

| 'toString' '(' e::Expr_c ')'
  {  top.ast = toStr(e.ast, location=top.location); }

| 'scan' '('')'
  {  top.ast = scan(location=top.location); }

| 'hasKey' '(' e::Expr_c ',' key::Expr_c ')'
  { top.ast = hasKey(e.ast, key.ast, location=top.location); }


concrete productions top::BuildEventFields_c
| 
  { top.ast = nilBuildEventFields(location=top.location); }
| name::Id_t '=' e::Expr_c
  { top.ast = consBuildEventFields(name.lexeme, e.ast,
                                   nilBuildEventFields(location=top.location), 
                                   location=top.location); }
| name::Id_t '=' e::Expr_c ',' rest::BuildEventFields_c
  { top.ast = consBuildEventFields(name.lexeme, e.ast, rest.ast,
                                   location=top.location); }


concrete productions top::Exprs_c
| e::Expr_c
  { top.ast = addExprs(e.ast, emptyExprs(location=top.location),
                       location=top.location); }
| e::Expr_c ',' rest::Exprs_c
  { top.ast = addExprs(e.ast, rest.ast, location=top.location); }