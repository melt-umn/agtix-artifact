# AGTix

This artifact accompanies the tool paper 'AGTix: Concise Definition of Scope
Graphs in Reference Attribute Grammars' of Luke Bessant and Eric Van Wyk,
submitted to [ACM SIGPLAN SLE 2026](https://conf.researchr.org/home/sle-2026).
Its purpose is to demonstrate the use of AGTix constructs for specifying the
construction and interrogation of scope graphs, which are implemented as a
language extension to the reference attribute grammar language Silver.

AGTix is a fusion of [Statix](https://spoofax.dev/references/statix/) 
(inspiration for the constructs introduced is primarily inspired by
[MiniStatix](https://github.com/metaborg/ministatix.hs)) and reference
attribute grammars ([Silver](github.com/melt-umn/silver) specifically), which
brings Statix-like constraints for building and querying scope graphs into RAGs
as new equation forms, implemented as a language extension to Silver. This
allows a much more concise definition of scope graph-based name analysis than
is yielded by the full Statix-to-RAGs translation of our 
[previous work](https://dl.acm.org/doi/pdf/10.1145/3732771.3742711). The new
AGTix constructs implicitly translate to attribute declarations/definitions
and production equations akin to what is presented in that previous work, hiding
the details such as how targets of edge assertions are propagated around an
AST, which often involve many more equations and definitions than what AGTix
specifications yield. It also means that Statix specifications can be more
easily translated to RAG specifications, as a consequence of AGTix is that these
now have a much closer line-to-line correspondence.

The artifact contains a number of example languages with name resolution
semantics defined using AGTix, scripts for compiling those languages, and other
scripts for executing each with test input programs which compare output against
expected results. Packaged with this artifact are the Silver Jarfiles for the
latest version of AGTix.

## Authors

- Luke Bessant (bessa02@umn.edu)
- Eric Van Wyk (evw@umn.edu)

## Artifact structure

```
.
├── run-tests             # Script to run all test inputs for all test languages (invokes grammars/test-all)
├── grammars              # Directory holding grammars for testing languages
│   ├── test-all          # Script to run all test inputs for all test languages
│   ├── test-one          # Script with function allowing individual grammars to execute individual test inputs
│   ├── comscan/          # Directory for ComScaN test case
│   │   ├── comscan/      # Contains grammar for ComScaN language
│   │   ├── inputs/       # Test inputs
│   │   ├── lib/          # Extra ComScaN programs for 'library' definitions, included in all tests for this language
│   │   ├── compile       # Compile script
│   │   ├── run-test      # Script to run an individual test input
│   │   ├── clean         # Cleanup grammar dir
│   │   └── README.md     # Overview of this example language
│   ├── lm1/              # Directory for LM version 1 test case, similar
│   │   └── ...           # Contents similar to comscan directory
│   └── lm2/              # Directory for LM version 2 test case
│       └── ...           # Contents similar to comscan directory
├── jars/                 # Contains JAR files for AgTix/Silver
├── tools/                # Home for certain scripts
│   └── silver            # Script for invoking Siler with JARs in jars/
├── gen/                  # Directory for Silver-generated files, created when languages are compiled - can be ignored
├── Dockerfile            # Dockerfile for making an image of this artifact
├── docker-image          # Script to generate and execute artifact docker image
├── README.md             # Project overview
└── AUTHORS-TEMPLATE.md   # Artifact information for SLE kick-the-tires review
```

## AGTix constructs

This section gives an overview of the syntactic constructs that AGTix introduces
to Silver, and their meaning. The examples used are taken from the example
language [lm1](./grammars/lm1/).

### Scope graph labels declaration

The `scope labels` syntax declares the existence of a type of scope graph whose
label set is taken from the labels listed e.g. `` `lex`` in the example below.
The user gives an identifier for this set of labels, which can be referred to
in the rest of the attribute grammar. Here, we call the set `LMLabels`.

```
scope labels `lex, `var, `mod, `imp as LMLabels;
```

### Scope attributes

AGTix introduces a new kind of attribute called a 'scope' attribute for
propagating scope graph nodes down an abstract syntax tree. Here we define a
new scope attribute called `s`, and declare which nonterminals it occurs on.
Note that the occurrence declarations can be separate from the scope attribute
declaration e.g. `attribute s occurs on Decls;`, or `nonterminal Decls with s;`
when declaring nonterminal types.

```
scope attribute s occurs on Decls, Decl, Module, ParBinds, Expr, Binds, Bind;
```

### Scope and edge assertion

Scope graph nodes are introduced using `newScope` syntax. The user provides an
identifier for the scope, and can optionally declare data associated with it to
be used in name resolution. In AGTix, the data associated with a scope must be
a tree of type `Datum`, which the user must define productions for. Edges 
assertions take the form ``s1 -[ `l ]-> s2;``, introducing an edge of label
`` `l`` from scope `s1` to `s2`, or ``top.s -[ `l ]-> s2`` to assert an edge
whose source is a scope attribute `s` on AST node `top` (see below). 
The `declsCons` example below, for lists of declarations, introduces a new scope
`seqScope` and a `` `lex`` edge from it to `top.s`, a scope attribute `s` on
node `top` (the AST node built by `declsCons`).
```
abstract production declsCons
top::Decls ::= d::Decl ds::Decls
{
  newScope seqScope;
  seqScope -[ `lex ]-> top.s;
  ...
}
```
Here we introduce a scope `modScope` with associated data `datumMod(x, top)` for
use in name resolution. Notably, `top` is a reference to the 'local' node built
by the `module` production. We then assert the existence of three edges, one
sourced at `modScope`, and two sourced at scopes passed down the tree as scope
attributes on `top`.
```
abstract production module
top::Module ::= x::String ds::Decls
{
  newScope modScope -> datumMod(x, top);
  modScope -[ `lex ]-> top.s;
  top.s_def -[ `mod ]-> modScope;
  top.s_module -[ `mod ]-> modScope;
  ...
}
```
AGTix also has syntax ``s -[[ `lex ]]-> [s1, s2, s3];`` to allow users to 
assert multiple edges at a time.

### Queries

Queries are expressions used in name resolution. Queries take as arguments:

- a path well-formedness regular expression determining what paths can be taken
  in the scope graph from the query source to declarations,
- an optional label ordering for defining shadowing for a query,
- a predicate of type `Boolean ::= Datum` (`Datum -> Boolean` in conventional
  notation) which determines which declarations at the end of valid paths are
  desired,
- a source scope.

The below snippet contains an example of a query which returns scope graph nodes
whose datum is `datumVar(dx, _)` where `dx` matches `x`, the variable reference,
found by following paths starting at scope `top.s` consisting of a possibly
empty sub-path of `` `lex`` edges, an optional `` `imp`` edge, and ending in
with a `` `var`` edge.
```
abstract production varRef
top::VarRef ::= x::String
{
  local exact::[Decorated Scope with LMLabels] =
    query(`lex* `imp? `var,
          `var < `imp < `lex,
          \d::Datum -> case d of datumVar(dx, _) -> x == dx | _ -> false end,
          top.s);
  ...
}
```
The optional label ordering can be removed to produce the following query which
now no longer shadows paths.
```
abstract production varRef
top::VarRef ::= x::String
{
  local exact::[Decorated Scope with LMLabels] =
    query(`lex* `imp? `var,
          \d::Datum -> case d of datumVar(dx, _) -> x == dx | _ -> false end,
          top.s);
  ...
}
```

## Usage

### Testing all grammars

```
./run-tests
./grammars/test-all   # alternate
```

### Testing a single grammar

E.g. executing a test input for grammar `lm1`:

```
cd grammars/lm1
./test-one inputs/simple-vars.tst
```

Alternatively:

```
cd grammars/lm1
./compile
java -jar lm1.jar inputs/simple-vars.tst    # Compile one test input
cat inputs/simple-vars.tst.out              # Compare output of above with this
```

Or the following, which will `diff` the output of `run-test` with the file
`inputs/simple-vars.tst.out`:

```
cd grammars/lm1
./run-test inputs/simple-vars.tst
```

## Building AGTix

This artifact contains the Silver/AGTix JAR files yielded by building 
[Silver](github.com/melt-umn/silver) in the
[scopegraphs](https://github.com/melt-umn/silver/tree/feature/scopegraphs/)
feature branch. However, if the reviewer wishes to reproduce these JARs
themselves, they can execute either of the following commands once the
`scopegraphs` branch is checked out.

1. `./fetch-jars` will fetch the latest JARs for the `scopegraphs` feature
  branch build from our Jenkins system. Whenever a new change is pushed to this
  branch, new JARs are built in Jenkins.
2. `./deep-rebuild` will build the JARs for Silver/AGTix locally.

In either case, the JARs will be put in the `silver/jars` directory. When
producing this artifact, this directory was simply copied to 
`agtix-artifact/jars`.
