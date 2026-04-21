grammar lm2;

imports lm2:concretesyntax;
imports lm2:nameanalysis;

parser parse :: Main_c {
  lm2:concretesyntax;
}

function main
IO<Integer> ::= largs::[String]
{
  return
    if !null(largs)
      then do {
        let filePath :: String = head(largs);
        file :: String <- readFile(head(largs));

        let fileName::String = head(explode(".", last(explode("/", filePath))));

        let result :: ParseResult<Main_c> = parse(file, filePath);
        let ast :: Main = result.parseTree.ast;

        let fileNameExt::String = last(explode("/", filePath));
        let fileNameExplode::[String] = explode(".", fileNameExt);
        let fileName::String = head(fileNameExplode);

        if result.parseSuccess
          then do {
            if length(fileNameExplode) >= 2 && last(fileNameExplode) == "tst"
              then do {
                print("[✔] Parse success\n");
                res::Integer <-
                  if null(ast.errs)
                  then 
                  do {
                    print("[✔] Semantic check successful\n");
                    --mkdir("out");
                    --writeFile("out/" ++ fileName ++ ".ml", ast.ocaml);
                    return 0;
                  }
                  else do {
                    print("[✗] Semantic check failed with the following errors:\n" ++
                          concat(map(\msg::String -> "  - " ++ msg, ast.errs)));
                    return -1;
                  };
                return res;
              }
              else do {
                print("[✗] Expected an input file of form [file name].tst\n");
                return -1;
              };
          }
          else do {
            print("[✗] Parse failure\n" ++ result.parseErrors);
            return -1;
          };
      }
      else do {
        print("[✗] No input file given\n");
            return -1;
      };
}
