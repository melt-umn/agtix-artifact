grammar comscan:declareAssign:concreteSyntax;

imports comscan:host:concreteSyntax;

concrete production declAssignDeclaration 
top::Declaration_c ::= ty::Type_c name::Id_t '=' e::Expr_c ';'
{
  forwards to declWithMods_c(
    ^ty, name,
    modifiersOne_c(
      defaultModifier_c(
        'default', ^e,
        location=top.location
      ),
      location=top.location
    ),
    ';',
    location=top.location
  );
}
