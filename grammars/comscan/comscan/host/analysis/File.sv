grammar comscan:host:analysis;

--

function decFiles
(Decorated Scope with CSLabels, Decorated Files with { mainFileName, s}) ::=
  mainFileName::String
  fs::Files
{
  newScope globScope;
  
  fs.s = globScope;
  fs.mainFileName = mainFileName;

  return (globScope, fs);
}


--

inherited attribute mainFileName::String;
monoid attribute hasMainActor::Boolean with false, ||;

--

nonterminal Files with msgs, s, eventTypes, mainFileName;
propagate msgs, s, eventTypes, mainFileName on Files;

abstract production filesNil
top::Files ::=
{
}

abstract production filesCons
top::Files ::= h::FileUnit t::Files
{
}

--

nonterminal FileUnit with location, name, msgs, s, eventTypes, mainFileName;
propagate eventTypes on FileUnit;

abstract production fileUnit
top::FileUnit ::= name::String file::File
{
  top.name = name;

  newScope fileScope -> datumFile(top);
  fileScope -[ `lex ]-> top.s;

  file.s = fileScope;

  top.s -[ `file ]-> fileScope;

  top.msgs :=
    if name == top.mainFileName && !file.hasMainActor
    then [ errMessage(name ++ " must have a Main actor definition", top.location) ]
    else file.msgs;
}

--

nonterminal File with location, msgs, s, eventTypes, hasMainActor;
propagate msgs, s, eventTypes, hasMainActor on File;

abstract production file
top::File ::= d::TopDcls
{}

--

nonterminal TopDcls with location, msgs, s, eventTypes, hasMainActor;
propagate msgs on TopDcls excluding branchTopDcls, importTopDcls;
propagate s, eventTypes, hasMainActor on TopDcls;

abstract production branchTopDcls
top::TopDcls ::= d1::TopDcls d2::TopDcls
{
  top.msgs := if !null(d1.msgs) then d1.msgs else d2.msgs;
}

abstract production nilTopDcls
top::TopDcls ::=
{
}

abstract production actorTopDcls
top::TopDcls ::= d::ActorDcl
{
}

abstract production eventTypeTopDcls
top::TopDcls ::= d::EventTypeDcl
{
}

abstract production importTopDcls
top::TopDcls ::= filepath::String
{
  local filename::String = fileNameInFilePath(filepath);
  local edgesMsgs::([Decorated Scope with CSLabels], [Message]) =
    case query(`lex `file, isName(filename), top.s) of
    | []    -> ([], [errMessage("could not resolve file " ++ filename, top.location)])
    | h::[] -> ([h], [])
    | _     -> ([], [errMessage("ambiguous file reference " ++ filename, top.location)])
    end;

  top.s -[[ `imp ]]-> edgesMsgs.1;

  top.msgs := edgesMsgs.2;
}
