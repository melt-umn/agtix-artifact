# Artifact Submission Template for SLE

## Author Information
- **Names:** Luke Bessant, Eric Van Wyk
- **Affiliations:** University of Minnesota
- **Emails:** bessa028@umn.edu, evw@umn.edu

## Associated Paper Information
- **Title:** Tool Paper: AGTix: Concise Definition of Scope Graphs in Reference Attribute Grammars
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
- **Link to the code repository:** https://github.com/melt-umn/agtix-artifact
- Describe the structure of the artifact and provide a brief overview of the contents.

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
2. **Run a Sample Command:** Provide a single command or a few minimal commands that verify the artifact is working.
3. **Expected Output:** Describe what the expected output should be.
4. **Troubleshooting:** List common issues and their possible solutions if the setup fails.

## Full Evaluation
For all experimental claims made in the paper, please provide the following:

1. **Reference to the Experimental Claim:** Quote or reference the claim from the paper.
2. **Reproduction Steps:** Explain how this claim can be reproduced using the artifact.
   - Example: *“The results presented in Figure 3 can be reproduced by executing `run_experiment.sh` with the configuration file `config_figure3.json`.”*
3. **Expected Output:** Clearly describe what the expected output should be.
4. **Estimated Runtime (Optional):** Provide an estimate of how long the full evaluation will take.
5. **Potential Issues:** List any known challenges in reproducing the results and how to mitigate them.
