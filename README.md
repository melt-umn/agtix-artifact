# AgTix

This artifact accompanies the tool paper [FINAL TITLE HERE] of Luke Bessant and
Eric Van Wyk, submitted to [ACM SIGPLAN SLE 2026](https://conf.researchr.org/home/sle-2026).

More content here to come...

## Artifact structure

```
.
├── run-tests         # Script to run all test inputs for all test languages (invokes grammars/test-all)
├── grammars
│   ├── test-all      # Script to run all test inputs for all test languages
│   ├── test-one      # Script with function allowing individual grammars to execute individual test inputs
│   └── lm1/          # Directory for LM version 1 test case
│       ├── lm1/      # Contains grammar for LM version 1
│       ├── inputs/   # Tetst inputs
│       ├── compile   # Compile script
│       ├── run-test  # Script to run an individual test input
│       └── clean     # Cleanup grammar dir
├── jars/             # Contains JAR files for AgTix/Silver
├── tools/
│   └── silver        # Script for invoking Siler with JARs in jars/
├── Dockerfile        # Dockerfile for making an image of this artifact
├── docker-image      # Script to generate and execute artifact docker image
└── README.md         # Project overview (this file)
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