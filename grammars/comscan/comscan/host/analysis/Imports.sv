grammar comscan:host:analysis;
imports comscan:host:concreteSyntax;

--

type Parser<a> = (ParseResult<a> ::= String String);

--

fun parseFiles
IO<Either<String Files>> ::= files::[String] p::Parser<File_c> = do {
  case files of
  | [] -> pure(right(filesNil()))
  | h::t -> do {
    cont::Either<String Files> <- parseFiles(t, p);
    case cont of
    | left(_)  -> pure(cont)
    | right(lst) -> parseFile(h, p, lst)
    end;
  }
  end;
};

fun parseFile
IO<Either<String Files>> ::= fileName::String p::Parser<File_c> acc::Files = do {

  exists::Boolean  <- isFile(fileName);
  contents::String <- readFile(fileName);

  let parsed::ParseResult<File_c> = p(contents, fileName);
  let file::File = parsed.parseTree.ast;

  let fileu::FileUnit = fileUnit(fileNameInFilePath(fileName), 
                                 file, location=file.location);
  
  return
    if !exists
    then left("Required file " ++ fileName ++ " does not exist\n")
    else if !parsed.parseSuccess 
    then left("Required file " ++ fileName ++ " did not parse:\n" ++ 
              parsed.parseErrors ++ "\n")
    else right(filesCons(fileu, acc));
};
