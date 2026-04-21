# Artifact Submission Template for SLE

## Author Information
- **Names:** Luke Bessant, Eric Van Wyk
- **Affiliations:** University of Minnesota
- **Emails:** bessa028@umn.edu, evw@umn.edu

## Associated Paper Information
- **Title:**

Tool Paper: AGTix: Concise Definition of Scope Graphs in Reference Attribute Grammars

- **Abstract:**

This tool paper introduces AGTix, an extension to reference attribute grammars
that allows constraints, inspired by Visser et al.’s Statix system, that
construct and query scope graphs to be written alongside traditional attribute
equations. Previous work has shown that a restricted form of Statix
specifications can be translated to an equivalent reference attribute grammar
that produces the same results; however, the resulting attribute grammar is
quite verbose. In AGTix specifications, the more concise constraints for
specifying new scope nodes or edges are translated down to the verbose equations
which propagate scope node and edge information up and down the syntax tree. The
query constructs for resolving names are translated down to expressions; as in
Statix, these include syntax for regular expressions over edge labels that
describe the valid paths for a resolution. The scope graphs and query results
described by these new constructs can be used in traditional attribute grammar
equations for other language processing tasks such as collecting error and
warning messages or using variable types to support a translation to another
language. AGTix is implemented as a modular extension to Silver, a full-featured
extensible attribute grammar system, and is evaluated by implementing several
variations of the LM language introduced by Visser et al. for investigating the
expressiveness of scope graphs and Statix.

## Documentation
- **Link to the code repository:**

https://github.com/melt-umn/agtix-artifact

- **Describe the structure of the artifact and provide a brief overview of the contents.**

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

```
.
├── run-tests             # Script to run all test inputs for all test languages (invokes grammars/test-all)
├── grammars              # Directory holding grammars for testing languages
│   ├── test-all          # Script to run all test inputs for all test languages
│   ├── test-one          # Script with function allowing individual grammars to execute individual test inputs
│   └── lm1/              # Directory for LM version 1 test case
│       ├── lm1/          # Contains grammar for LM version 1
│       ├── inputs/       # Test inputs
│       ├── compile       # Compile script
│       ├── run-test      # Script to run an individual test input
│       └── clean         # Cleanup grammar dir
├── jars/                 # Contains JAR files for AgTix/Silver
├── tools/                # Home for certain scripts
│   └── silver            # Script for invoking Siler with JARs in jars/
├── Dockerfile            # Dockerfile for making an image of this artifact
├── docker-image          # Script to generate and execute artifact docker image
├── README.md             # Project overview
└── AUTHORS-TEMPLATE.md   # Artifact information for SLE kick-the-tires review
```

---

## Artifact Evaluation Environment

### System Specifications Used by Authors

- **Operating System:**

EndeavourOS Linux x86_64 (Kernel: 6.18.9-arch1-2)

- **CPU:** 

11th Gen Intel i5-1135G7 (8) @ 4.200GHz

- **Memory:**

16GB DDR4

- **Disk Space:**

500 GB

- **GPU (if applicable):**

Not applicable.

### Estimated Hardware Requirements for Evaluation

- **Minimum required CPU:**

No strict requirements.

- **Minimum required Memory:**

1.3GB (Max memory usage of `time ./run-tests`, to nearest 0.1GB)

- **Minimum required Disk Space:**

1.6GB (Docker image size)

- **Minimum required GPU (if applicable):**

Not applicable.

### Compatibility Considerations

- **Known compatibility issues of the container/VM:**
Not applicable.

## Kick-the-Tires
This section should provide a simple and quick way for the reviewer to check whether all dependencies are correctly installed and that all scripts run without errors. The goal is not to run the full evaluation but to verify that the artifact is functional.

### Steps to Perform a Quick Test

1. **Setup Instructions:** Describe the minimal steps needed to set up the environment.

The reviewer should load and run the AGTix Docker image as below:
```
docker load -i agtix-docker.tar
docker run -ti agtix:latest
```

2. **Run a Sample Command:** Provide a single command or a few minimal commands that verify the artifact is working.

Then to check that Silver/AGTix are able to be built, we can try building the
compiler of one of the example languages e.g. LM1:

```
./grammars/lm1/compile
```

3. **Expected Output:** Describe what the expected output should be.

The reviewer should be able to see the Ant build process starting with:
```
Found lm1
	[./grammars/lm1/../../gen/src/lm1/Silver.svi]
Found lm1:concretesyntax
	[./grammars/lm1/../../gen/src/lm1/concretesyntax/Silver.svi]
Found lm1:nameanalysis
	[./grammars/lm1/../../gen/src/lm1/nameanalysis/Silver.svi]
...
```

And ending with:
```
BUILD SUCCESSFUL
Total time: n seconds     # for some n
```

4. **Troubleshooting:** List common issues and their possible solutions if the setup fails.
No known issues.

## Full Evaluation
For all experimental claims made in the paper, please provide the following:

### AGTix - Reference attribute grammars + Statix

1. **Reference to the Experimental Claim:** Quote or reference the claim from the paper.

AGTix is a combination of reference attribute grammars (RAGs) and Statix, that
provides a means for implementing in RAGs the name resolution semantics of
languages using Statix constraint-like syntax. Our claim is that, on top of
AGTix constructs building and querying scope graphs correctly, these two
styles compose well together, and the examples we provide in this artifact are
evidence of that.
We show below code snippets that illustrate the use of AGTix constructs 
(identified by comments '--') for declaring scope graphs and scope attributes, 
building and querying scope graphs, as well as propagating scopes down an AST as
scope attributes. These snippets come from code included in this artifact, in:
`grammars/lm2/lm2/nameanalysis/Scoping.sv`.

The rest of the evaluation instructions following the snippets below describes
how to execute AGTix specifications of languages with test input programs
(including the one whose snippets are below), thus providing evidence that AGTix
is a fully-functional means for specifying scoping semantics of languages.

Scope graph declaration and example scope attribute:

```
-- AGTix: Declare a new type of scope graph whose labels are 'lex', 'var', 'mod',
-- and 'imp'. Make an alias for this label set called 'LMLabels' (used in the
-- module reference example).
scope labels lex, var, mod, imp as LMLabels;

-- AGTix: Define a new scope attribute 's' which occurs on the nonterminals
-- listed after 'occurs on'. A scope attribute is a kind of inherited attribute
-- that also introduces new synthesized attributes for lifting references to
-- edge targets up the AST to where a scope is defined.
scope attribute s occurs on Decls, Decl, Module, ParBinds, Expr, Binds, Bind;

-- AGTix: Other scope attribute examples:
scope attribute s_last occurs on Binds;
scope attribute s_dcl occurs on Bind;
scope attribute s_module occurs on Decls, Decl, Module;
scope attribute s_def occurs on Decl, Module, ParBinds;
```

Sequential let expression:

```
-- Sequential let expression production
abstract production exprLet
top::Expr ::= bs::Binds e::Expr
{ 
  -- AGTix: Asserting the existence of a scope called s_let, built down in subtree 'bs'
  existsScope s_let;
  
  -- AGTix: Defining scope attribute 's' for subtree 'bs' as top.s, the scope of this expression.
  -- Hides details of how edge targets are propagated around the AST implicitly for building scope graphs
  bs.s = top.s;
  
  bs.s_last = s_let;
  
  -- AGTix: Defining scope attribute 's' for subtree 'e' as s_let, the scope
  -- whose existence is asserted here, but is build down in subtree 'bs'.
  -- Hides details of how edge targets are propagated around the AST implicitly for building scope graphs
  e.s = s_let;
  
  top.errs = bs.errs ++ e.errs;
  top.type = e.type;
}

-- Production for the last binding in a sequential let binding list
abstract production seqBindsLast
top::Binds ::= b::Bind
{ 
  -- AGTix: Asserting the existence of a scope called s_dcl, built down in subtree 'b'
  existsScope s_dcl;
  
  -- AGTix: Constructing scope top.s_last, passed down as a scope attribute to this production
  newScope top.s_last;
  
  -- AGTix: Asserting a 'lex' edge from top.s_last (built above) to top.s, the previous scope built in a sequential let binding list
  top.s_last -[ lex ]-> top.s;
  
  -- AGTix: Asserting a 'var' edge from top.s_last (built above) to s_dcl, built down in subtree 'b'
  top.s_last -[ var ]-> s_dcl;
  
  b.inSeqLet = true;

  -- AGTix: Defining scope attribute 's' for subtree 'b' as top.s.
  -- Hides details of how edge targets are propagated around the AST implicitly for building scope graphs
  b.s = top.s;

  -- AGTix: Defining scope attribute 's_dcl' for subtree 'd' as s_dcl.
  -- Hides details of how edge targets are propagated around the AST implicitly for building scope graphs
  b.s_dcl = s_dcl; 
  
  top.errs = b.errs;
}
```

Module declaration:

```
-- Production for declaring modules 'mod A { ... }'
abstract production module
top::Module ::= x::String ds::Decls
{
  -- AGTix: Building a new scope called modScope whose associated data is
  -- datumMod(x, top) - the module name and reference to this node in the AST
  newScope modScope -> datumMod(x, top);

  -- AGTix: Asserting a 'lex' edge from modScope to top.s, the scope of the enclosing module
  modScope -[ lex ]-> top.s;

  -- AGTix: Asserting a 'mod' edge from top.s, the scope of the enclosing module, to modScope
  top.s -[ mod ]-> modScope;
  
  -- AGTix: Defining scope attribute 's' for subtree 'ds' as modScope.
  -- Hides details of how edge targets are propagated around the AST implicitly for building scope graphs
  ds.s = modScope;

  top.errs = ds.errs;
}
```

Import resolution:

```
-- Production for module references in import declarations
abstract production modRef
top::ModRef ::= x::String
{
  -- AGTix: A query for resolving imports with a path well-formedness regex, 
  -- label ordering for shadowing, resolution predicate, and starting scope
  local mods::[Decorated Scope with LMLabels] =
    query(`lex+ `imp? `mod,
          `mod < `imp < `lex,
          isModuleCalled(x), top.s);
  
  local s_res::Decorated Scope with LMLabels =
    if length(mods) == 1 then head(mods) else deadScope;

  -- AGTix: Asserting an edge from top.s, the scope of the enclosing module,
  -- to s_res, the module scope found in the resolution of 'x'
  top.s -[ imp ]-> s_res;

  top.errs = 
    case mods of
    | h::[] -> []
    | _::_  -> [err("ambiguous module reference " ++ x, top.location)]
    | []    -> [err("unresolvable module reference " ++ x, top.location)]
    end;
}
```

2. **Reproduction Steps:** Explain how this claim can be reproduced using the artifact.
   - Example: *“The results presented in Figure 3 can be reproduced by executing `run_experiment.sh` with the configuration file `config_figure3.json`.”*


Once inside the artifact Docker image using the steps described above in the
'quick test' section, the reviewer should run `./run-tests` in the immediate
directory to invoke the testing harness. This runs all test input programs for
all of the example languages whose name binding semantics we specify in AGTix.

3. **Expected Output:** Clearly describe what the expected output should be.

The expected output of `./run-tests` are as follows. The output is comprised of
runs of test input programs for all of the example languages, written with
AGTix, provided. Each example language block reports the number of failed tests
for that language. The final report says that the grammars for all example
languages were compiled successfully, and that they passed all tests. If
example languages fail to build, this will be reported in the final report, as
will the names of example languages which failed to produce expected results
for at least one test input program.

```
--------------------------------------------------
-- Testing harness for AgTix ---------------------
--------------------------------------------------
- Compiling grammar lm1
- Executing tests inputs for lm1
	[1/16] lm1/inputs/forward-vars.tst PASSED
	[2/16] lm1/inputs/function-app.tst PASSED
	[3/16] lm1/inputs/function-unresolvable-close.tst PASSED
	[4/16] lm1/inputs/function-unresolvable.tst PASSED
	[5/16] lm1/inputs/letpar.tst PASSED
	[6/16] lm1/inputs/letrec.tst PASSED
	[7/16] lm1/inputs/modules-import-circ.tst PASSED
	[8/16] lm1/inputs/modules-import-nested-unresolvable.tst PASSED
	[9/16] lm1/inputs/modules-import-nested.tst PASSED
	[10/16] lm1/inputs/modules-import-unresolvable.tst PASSED
	[11/16] lm1/inputs/modules-import.tst PASSED
	[12/16] lm1/inputs/modules-no-import.tst PASSED
	[13/16] lm1/inputs/simple-vars-shadowed.tst PASSED
	[14/16] lm1/inputs/simple-vars-unresolvable-close.tst PASSED
	[15/16] lm1/inputs/simple-vars-unresolvable.tst PASSED
	[16/16] lm1/inputs/simple-vars.tst PASSED
- Number of failed tests for lm1: 0
--------------------------------------------------
- Compiling grammar lm2
- Executing tests inputs for lm2
	[1/16] lm2/inputs/forward-vars.tst PASSED
	[2/16] lm2/inputs/function-app.tst PASSED
	[3/16] lm2/inputs/function-unresolvable-close.tst PASSED
	[4/16] lm2/inputs/function-unresolvable.tst PASSED
	[5/16] lm2/inputs/letpar.tst PASSED
	[6/16] lm2/inputs/letrec.tst PASSED
	[7/16] lm2/inputs/modules-import-circ.tst PASSED
	[8/16] lm2/inputs/modules-import-nested-unresolvable.tst PASSED
	[9/16] lm2/inputs/modules-import-nested.tst PASSED
	[10/16] lm2/inputs/modules-import-unresolvable.tst PASSED
	[11/16] lm2/inputs/modules-import.tst PASSED
	[12/16] lm2/inputs/modules-no-import.tst PASSED
	[13/16] lm2/inputs/simple-vars-shadowed.tst PASSED
	[14/16] lm2/inputs/simple-vars-unresolvable-close.tst PASSED
	[15/16] lm2/inputs/simple-vars-unresolvable.tst PASSED
	[16/16] lm2/inputs/simple-vars.tst PASSED
- Number of failed tests for lm2: 0
--------------------------------------------------
-- Final report ----------------------------------
--------------------------------------------------
- All grammars compiled successfully
- Grammars that passed all tests:
	- lm1
- Test inputs successful for all grammars
--------------------------------------------------
```

4. **Estimated Runtime (Optional):** Provide an estimate of how long the full evaluation will take.

On the testing system specified above, `./run-tests` completed in 2 minutes,
5 seconds.


5. **Potential Issues:** List any known challenges in reproducing the results and how to mitigate them.

No known issues.
