# 'LM' Version 1 Example

## 'ComScan' Language Overview

### 1. Scoping

LM version 1 implements *sequential* scoping semantics. That is, every
declaration yields a new scope that is enclosed by the previous. This means
that there is no forward referencing; variable and import references may only
resolve to declarations previously in the same file. In the following program,
`y` will be unbound.
```
def y = x
def x = 1
```
And in the following program, the imports of `A` and `B` are unresolvable.
```
module C {
  import A
}
module A {
  import B
  module B {
  }
}
```
Whereas all names are correctly resolved in the following program.
```
def x = 1
def y = x

module A {
  module B {
  }
  import B
}

module C {
  import A
}
```

### 2. Language

#### Variable definitions

Variables can be defined within a module, or at the top level, in one of the 
following ways. In the first form, the type of `<id>` is inferred using the
expression `<expr>`. The second form types `<id>` as `<type>` and validates the
type of `<expr>` accordingly.
```
def <id> = <expr>;
def <id>:<type> = <expr>;
```
For example:
```
def foo1 = 3;
def foo2:int = 3;

def bar1 = false;
def bar2: bool = true;

def baz1 = 0.0;
def baz2: float = 1.0; 
```

#### Module definitions

Modules can be defined using the `module` keyword. These may be defined at the
top level or nested within other modules. The `<decls>` body of a module may be
a sequence of variable or module definitions, or import declarations.

```
module <id> { <decls> }
```
For example:
```
module A {
  def a = 1 + 2;
}

module B {
  module C {
    def c = false;
  }
  def b = true;
}
```

#### Imports

Imports bring into scope the variables and modules defined within the imported
module. Imports declarations may exist within a module body, or at the top
level.
```
import <id>;
```
For example:
```
module A {
  def a = 1 + 2;
}

module B {
  module C {
    def c = false;
  }
  import A;
  import C;
  def b = a + if c then 1 else 2;
}

import A;
import B;

def x = a + b;
```

#### Types

The types defined for LM, all in the standard way, are:
- `float`
- `int`
- `bool`
- `t1 -> t2` for types `t1` and `t2`

#### Expressions

##### Variable reference

Variable references such as `x` refer to declared variables (see Scoping section
for semantics).

##### Constants

LM supports the following constants:

- Integers e.g. `1` as constants of type `int`,
- Floats e.g. `1.0` as constants of type `float`,
- `true` and `false` as constants of type `bool`.

##### Addition

Addition is defined in the standard way:

```
<expr> + <expr>
```

##### Conjunction

Conjunction is defined in the standard way:

```
<expr> & <expr>
```

##### Equality

Equality is defined in the standard way:

```
<expr> == <expr>
```

##### Lambda

Lambdas are defined with the `fun` keyword and may declare multiple arguments
along with type annotations for them.

```
fun (<id1>:<type1>, ..., <idn>:<typen>) { <expr> }
```
For example:
```
fun(x:int){x + 1}
```

##### Application

Lambdas can be applied using the `apply` keyword as below.
```
apply(<expr>, <expr>)
```
For example:
```
def addOneToTwo = apply(fun(x:int){x + 1}, 2)
```

##### Branching

Branching `if` expressions are defined in the usual way.
```
if <expr> then <expr> else <expr>
```
For example:
```
def x = true
def y = false
def z = if x & y then 1 + 2 else 3 + 4
```

##### Sequential let

Sequential let expressions take the following form. Within a sequential let
binding list, each successive binding may use only the previous ones in its
definition, or other variables in scope outside of the let expression.
```
let
  <id1> = <expr1>,       // or <id1>:<type1> = <expr1>
  ...
  <idn> = <exprn>
in
  <expr>
```
For example:
```
let
  x = 1,
  y = 2,
  z = x + y
in
  x + y + z
```

##### Recursive let

Recursive let expressions take the following form. Within a recursive let
binding list, each binding may use any others in the same binding list in its
definition, as well as other variables that are in scope.
```
letrec
  <id1> = <expr1>,
  ...
  <idn> = <exprn>
in
  <expr>
```
For example:
```
letrec
  x = z
  y = 3
  z = y
in
  x + y + z
```

##### Parallel let

Parallel let expressions take the following form. Within a parallel let binding
list, none of the names defined may use any others in their definition. Instead,
variables in the defining expressions are resolved in the scope that encloses
the parallel let expression.
```
letpar
  <id1> = <expr1>,
  ...
  <idn> = <exprn>
in
  <expr>
```
For example:
```
def x = 1
def y = 2
def z = 
  letpar
    y = x       // refers to the 'x' on line 1
    x = y       // refers to the 'y' on line 2
  in
    x + y       // refers to 'x' on line 6 and 'y' on line 5
```
