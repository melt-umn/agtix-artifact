grammar lm2:nameanalysis;

--

imports silver:compiler:extension:scopegraphs;

--

production datumVar
top::Datum ::= name::String b::Decorated Bind with {s, inSeqLet}
{}

production datumMod
top::Datum ::= name::String m::Decorated Module
{}

--

global deadScope::Decorated Scope with LMLabels = 
  decorate scope(datumDefault()) with { lex = []; var = []; mod = []; imp = []; };
