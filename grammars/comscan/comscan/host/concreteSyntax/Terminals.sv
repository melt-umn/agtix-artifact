grammar comscan:host:concreteSyntax;

imports comscan:host:analysis;


lexer class KEYWORD dominates {Id_t};
lexer class TYPE dominates {Id_t};

terminal Id_t      /[a-zA-Z][a-zA-Z0-9_]*/;

terminal Int_t     /-?[0-9]+/;
terminal True_t    'true'    lexer classes {KEYWORD};
terminal False_t   'false'   lexer classes {KEYWORD};
terminal String_t  /[\"]([^\r\n\"\\]|[\\][\"]|[\\][\\]|[\\]b|[\\]n|[\\]r|[\\]f|[\\]t)*[\"]/;
--terminal Bits_t    /0b[01]+/;

terminal Filename_t   /"[a-zA-Z0-9_\.\/]+"/;

terminal Actor_t     'actor'          lexer classes {KEYWORD};
terminal Action_t    'action'         lexer classes {KEYWORD};
terminal Handler_t   'handler'        lexer classes {KEYWORD};
terminal Control_t   'control'        lexer classes {KEYWORD};
terminal Init_t      'init'           lexer classes {KEYWORD};
terminal Event_t     'event'          lexer classes {KEYWORD};
terminal Start_t     'start'          lexer classes {KEYWORD};
terminal Import_t    'import'         lexer classes {KEYWORD};

terminal Send_t     'trigger'  lexer classes {KEYWORD};
terminal To_t       'for'      lexer classes {KEYWORD};
terminal Remove_t   'remove'   lexer classes {KEYWORD};
terminal From_t     'from'     lexer classes {KEYWORD};
terminal End_t      'end'      lexer classes {KEYWORD};
terminal Ty_t       'type'     lexer classes {KEYWORD};

terminal Extends_t   'extends' lexer classes {KEYWORD};
terminal With_t      'with'    lexer classes {KEYWORD};

terminal Print_t     'print'   lexer classes {KEYWORD};
terminal Scan_t      'scan'     lexer classes {KEYWORD};
terminal ToString_t  'toString'   lexer classes {KEYWORD};
terminal HasKey_t    'hasKey'   lexer classes {KEYWORD};

terminal Arrow_t   '->';

terminal LCurly_t   '{';
terminal RCurly_t   '}';
terminal LAngle_t   '<';
terminal RAngle_t   '>';
terminal LSq_t      '[';
terminal RSq_t      ']';
terminal LParen_t   '(';
terminal RParen_t   ')';

terminal Comma_t   ',';
terminal Semi_t    ';';
terminal Colon_t   ':';
terminal Eq_t      '=';

terminal Dot_t      '.';
terminal Percent_t  '%';
terminal Plus_t     '+';
terminal Minus_t    '-';
terminal Mult_t     '*';
terminal Or_t       '||';
terminal And_t      '&&';
terminal BitOr_t    '|';
terminal BitAnd_t   '&';
terminal Not_t      '!';
terminal BitNot_t   '~';
terminal DEq_t      '==';
terminal NEq_t      '!=';
terminal Ge_t       '>=';
terminal Le_t       '<=';
terminal LShift_t   '<<';
terminal RShift_t   '>>';
terminal Append_t   '++';

terminal If_t     'if'     lexer classes {KEYWORD};
terminal Else_t   'else'   lexer classes {KEYWORD};

terminal Match_t     'match'     lexer classes {KEYWORD};

--terminal LPM_t       'lpm'       lexer classes {KEYWORD};
--terminal Ternary_t   'ternary'   lexer classes {KEYWORD};
--terminal Exact_t     'exact'     lexer classes {KEYWORD};
--terminal Size_t      'size'      lexer classes {KEYWORD};
terminal Default_t   'default'   lexer classes {KEYWORD};

terminal IntTy_t     'int'               lexer classes {TYPE};
terminal BoolTy_t    'bool'              lexer classes {TYPE};
terminal Table_t     'table'             lexer classes {TYPE};
terminal StringTy_t  'string'            lexer classes {TYPE};
--terminal BitTy_t     'bits'              lexer classes {TYPE};
--terminal ConnArr_t   'connectionArray'   lexer classes {TYPE};

ignore terminal Spacing_t       /[\ \t\r\n]+/;
ignore terminal Comment_t       /\/\*(\/\*([^\*]|\*+[^\/\*])*\*+\/|[^\*]|\*+[^\/\*])*\*+\//;
ignore terminal LineComment_t   /\/\/.*/;
