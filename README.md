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

## Artifact structure

```
.
├── run-tests             # Script to run all test inputs for all test languages (invokes grammars/test-all)
├── grammars              # Directory holding grammars for testing languages
│   ├── test-all          # Script to run all test inputs for all test languages
│   ├── test-one          # Script with function allowing individual grammars to execute individual test inputs
│   └── lm1/              # Directory for LM version 1 test case
│       ├── lm1/          # Contains grammar for LM version 1
│       ├── inputs/       # Tetst inputs
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

## Authors

- Luke Bessant (bessa02@umn.edu)
- Eric Van Wyk (evw@umn.edu)