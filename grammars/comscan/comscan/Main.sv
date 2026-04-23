grammar comscan;

imports silver:compiler:extension:scopegraphs;

imports comscan:host:concreteSyntax;
imports comscan:host:analysis;

parser p::File_c {
  comscan:host:concreteSyntax;
}

--

function main
IO<Integer> ::= args::[String]
{
  return 
  if !null(args)
  then do {
    parseRes::Either<String Files> <- parseFiles(args, p);
    case parseRes of
    | left(err) -> do {
        print("[✗] Parse failure\n" ++ err);
        return -1; 
      }
    | right(_) -> do {
        print("[✔] Parse success\n");
        let filesGlobScope::(Decorated Scope with CSLabels, Decorated Files with { mainFileName, s }) = 
          decFiles(head(args), parseRes.fromRight);
        let globScope::Decorated Scope with CSLabels = filesGlobScope.1;
        let fs::Decorated Files with { mainFileName, s } = filesGlobScope.2;
        if null(fs.msgs)
        then do {
          print("[✔] Semantic check successful\n");
          return 0;
        }
        else do {
          print("[✗] Semantic check failed with the following errors:\n" ++
                        concat(map((.pp), fs.msgs)));
          return -1;
        };
    }
    end;
  }
  else do {
    print("[✗] No input file given\n");
    return -1;
  };
}
