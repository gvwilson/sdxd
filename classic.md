# Dafny as a Programming Language

This is a compact summary of Dafny for an experienced programmer who
already knows Python, Pascal, Java, or JavaScript and wants to use Dafny
as an ordinary programming language. It deliberately omits the
specification and verification features (such as `assert`, `requires`,
`ensures`, `ghost`, `lemma`, `invariant`, `decreases`, `modifies`, and
`reads`). The same material is written to be unambiguous for LLMs.

## What Dafny is

Dafny is a statically typed, imperative, sequential, general-purpose
language. It has classes and traits (interfaces), algebraic datatypes,
generics, first-class functions, tuples, and rich immutable collection
types. Programs are stored in `.dfy` files; the `dafny` tool type-checks
and compiles them, and can compile the same program to several target
languages: C#, Java, JavaScript, Go, Python, and C++.

An executable program has exactly one entry point: a `Main()` method (or a
method marked `{:main}`). `Main` takes no parameters, or one parameter of
type `seq<string>` for command-line arguments.

```dafny
method Main(args: seq<string>) {
  print "Hello, world!\n";
}
```

## Program structure

- A `.dfy` file is a sequence of `include` directives followed by
  top-level declarations. Order of declarations does not matter.
- Declarations introduce types, modules, methods, functions, and
  constants (`const`).
- Code is grouped into modules. Modules can be nested, imported
  (`import`), and "opened" (`import opened`), which brings their names
  into scope unqualified. Modules support export sets for access control.

```dafny
module Geometry {
  class Point { var x: int; var y: int; }
}
```

## Types

### Basic types

- `bool` — booleans.
- `int` — mathematical (arbitrary precision) integers.
- `nat` — non-negative integers (a subset of `int`).
- `real` — mathematical real numbers.
- `char` — characters (Unicode by default).
- `string` — a built-in alias for `seq<char>`.
- Fixed-width bit-vector types, e.g. `bv8`, `bv16` (values are bit vectors).
- `ORDINAL` — well-founded ordinals (mostly used in specifications).

### Value vs. reference types

Value types (compared by value, immutable) include `bool`, `int`, `real`,
`char`, bit-vectors, tuples, and inductive datatypes. Reference types
(compared by identity, nullable) include classes, arrays, and traits.
The type `object` is the supertype of all reference types and includes
`null`.

### Collection types

Immutable, mathematical collections:

- `set<T>` — finite set.
- `iset<T>` — possibly infinite set.
- `multiset<T>` — set with multiplicities (a bag).
- `seq<T>` — finite sequence (a list).
- `map<K, V>` — finite map from `K` to `V`.
- `imap<K, V>` — partial (possibly infinite) map.

Arrays are mutable reference types: `array<T>` is one-dimensional;
`array2<T>`, `array3<T>`, etc. are multi-dimensional. Arrays have a
`Length` member (`a.Length`), are indexed with `a[i]`, and are created with
`new`.

### Compound and user-defined types

- **Tuples**: `(int, string)` is a tuple type; `(3, "three")` is a value.
- **Function (arrow) types**: `A -> B` (total), `A --> B` (partial),
  `A ~> B` (may read the heap). Functions are first-class values and can be
  written as lambdas: `x => x * x`.
- **Classes**: named reference types with fields, methods, and functions.
  Fields are declared with `var` and always need an explicit type.
- **Traits**: interfaces; a class or trait can extend multiple traits.
  Traits may declare methods, functions, and fields.
- **Inductive datatypes** (`datatype`): algebraic types with a fixed set of
  constructors, like ML/Haskell sum types.

  ```dafny
  datatype Tree = Leaf | Node(left: Tree, value: int, right: Tree)
  ```

  Each constructor `C` gives a test member `t.C?`, and named constructor
  parameters become destructors (`t.value`).
- **Coinductive datatypes** (`codatatype`): like datatypes but allowing
  infinite values (e.g. streams).
- **Type synonyms** (`type T = int`), **subset types**
  (`type T = x: int | 0 <= x`), and **newtypes** (`newtype Id = int`), which
  are distinct types with explicit conversion via `as`.
- **Iterators**: generator-like values that produce results with `yield`.

### Generics

Classes, datatypes, methods, and functions can take type parameters:

```dafny
datatype List<T> = Nil | Cons(T, List<T>)
```

Type parameters can declare characteristics such as `T(==)` (supports
equality) and `T(0)` (auto-initializable).

## Methods and functions

A **method** is a callable, effectful routine. Parameters are named; results
are named in a `returns` clause (Dafny has no single implicit return value).
Methods can be instance members (with an implicit `this`) or `static`.

```dafny
method Swap(x: int, y: int) returns (a: int, b: int) {
  a, b := y, x;
}
```

A class can declare **constructors** with `constructor`, including one
anonymous constructor.

A **function** is a pure, expression-bodied routine with no side effects.
In Dafny 4, a `function` is compiled (executable) by default; recursion is
allowed.

```dafny
function Factorial(n: int): int {
  if n == 0 then 1 else n * Factorial(n - 1)
}
```

## Statements

- **Variable declaration**: `var x := 5;` (type inferred) or
  `var x: int;`.
- **Assignment**: `x := y;`. Multiple assignment is parallel, so swapping
  works directly: `x, y := y, x;`.
- **Allocation**: `new` creates objects and arrays, e.g. `new Point`,
  `new int[10]`, `new int[3, 4]`.
- **Method call**: the target of the call's out-parameters are written on
  the left of `:=`, e.g. `a, b := Swap(1, 2);`.
- **Conditionals**: `if ... { } else { }`.
- **Pattern matching**: `match expr { case Ctor(...) => ... }` for datatypes.
- **Loops**: `while` with a guard, and `for` loops that iterate over ranges
  or collections, e.g. `for i := 0 to n` and `for x in xs`.
- **Control flow**: `break`, `continue`, `return`, and labeled statements
  (`label L:` ... `break L;`).
- **Output**: `print` writes values to standard output.
- **Runtime checks**: `expect` aborts the program if its boolean argument is
  false (this is an executable check, not a proof obligation).
- **Error propagation**: the `:-` (update-with-failure) operator returns
  early when a call yields a failure value, similar to `?` in Rust or
  exceptions in other languages (see `Std.Wrappers`).

## Expressions

- Boolean operators: `&&`, `||`, `!`; short-circuiting implication `==>`
  and if-and-only-if `<==>`.
- Comparisons chain: `0 <= i < j <= n` means `0 <= i && i < j && j <= n`.
- Integer `/` and `%` follow the Euclidean definition, so `%` is always
  non-negative (unlike C, Java, or C#).
- Conversions and type tests: `e as T` and `e is T`.
- Lambda expressions: `x => x + 1`.
- Conditionals and matches are also expressions:
  `if b then e1 else e2` and `match e { case ... => ... }`.
- Collection expressions: displays (`{1, 2, 3}`, `[1, 2, 3]`), set/map
  comprehensions, and `let` expressions.
- Operations: `+` concatenates sequences and unions sets; `*` intersects
  sets; `-` is set difference; `in`/`!in` test membership; `|s|` is the
  cardinality or length; sequence slicing `s[a..b]`; sequence update
  `s[i := x]`.

## Type inference and initialization

Local variables infer their types from their initializer. Dafny enforces
definite assignment: a variable must be initialized on all paths before it
is read.

# Standard Libraries

The Dafny standard libraries live under `Std`. They are available by adding
`--standard-libraries` to the compiler invocation and importing the desired
module (for example `import Std.Wrappers`). They are pre-verified, so using
them does not add verification work to your program. Modules that wrap
target-language functionality (`FileIO`, `Concurrent`, `Statistics`, and
date/time) are only available for the C#, Java, JavaScript, Go, and Python
backends.

## Frequently used, runtime-oriented libraries

- **`Std.Wrappers`** — small datatypes for common patterns:
  `Option<T>` (`Some`/`None`), `Outcome<E>` (`Pass`/`Fail`), and
  `Result<R, E>` (`Success`/`Failure`). These pair with the `:-` operator to
  give exception-like error propagation, and provide conversions between
  each other (`ToOption`, `ToResult`, `ToOutcome`, `Map`).
- **`Std.Strings`** — conversions between strings and common types such as
  `bool`, `int`, and `nat`. (General sequence operations live in
  `Std.Collections.Seqs`.)
- **`Std.Collections`** — submodules of functions and lemmas over the built-in
  collection types: `Sets`, `Isets`, `Seqs`, `Maps`, `Imaps`, and `Arrays`.
  `Seqs` covers filtering, finding, inserting/removing, reversing, zipping,
  flattening, sorting, and conversion to sets.
- **`Std.Math`** — basic integer math such as `Min`, `Max`, and `Abs`.
- **`Std.Base64`** — Base64 encoding and decoding, with both `uint8`- and
  `bv8`-based interfaces.
- **`Std.JSON`** — JSON serialization and deserialization (RFC 8259).
  A low-level, verified, zero-copy API operates on concrete syntax trees; a
  higher-level API operates on ordinary `string` values. Main entry points
  are `API.Serialize` and `API.Deserialize`.
- **`Std.DynamicArray`** — an array class that can grow and shrink with
  amortized constant-time push and constant-time pop.
- **`Std.BoundedInts`** — fixed-width integer types (`int8`..`int128`,
  `uint8`..`uint128`, and `nat8`..`nat128`) plus powers-of-two constants, so
  compiled programs can use native machine integers.

## Structural and algorithmic libraries

- **`Std.Actions`** — traits for modeling imperative, higher-order actions,
  including producers and consumers (`Producer`, `Consumer`,
  `IProducer`, `IConsumer`) for streaming values, and bulk operations such as
  `ForEach`, `Fill`, and `Map`.
- **`Std.Parsers`** — verified functional parser combinators in two styles
  (a plain function style and a builder/infix style), with combinators for
  alternatives, sequencing, repetition, mapping, and backtracking, plus
  precise failure reporting.
- **`Std.Unicode`** — scalar values, code points, and the UTF-8 and UTF-16
  encoding forms/schemes from Unicode 15.1, with conversion utilities.
- **`Std.Relations`** — properties of binary relations (reflexive,
  transitive, total/strict orderings, etc.); mainly used as proof support for
  sorting and similar routines.
- **`Std.Termination`** — a `TerminationMetric` datatype that represents
  decreases clauses as structured ordinal values (used heavily by
  `Std.Actions`).
- **`Std.Ordinal`** — additional axioms and operations for the `ORDINAL`
  type, including multiplication (`Times`).

## Proof-oriented support libraries

These are mainly collections of lemmas and properties rather than runtime
APIs:

- **`Std.Arithmetic`** — lemmas for non-linear arithmetic: multiplication,
  division/modulus, exponentiation, powers of two, logarithms, and
  little-endian natural numbers.
- **`Std.Functions`** — properties of functions.
- **`Std.Frames`** — utilities for dynamic framing (reads/modifies sets).

## Target-specific libraries (C#, Java, JavaScript, Go, Python)

- **`Std.FileIO`** — read bytes from a file and write bytes to a file.
- **`Std.Concurrent`** — types such as a `MutableMap` for sharing mutable
  state between concurrent executions of compiled Dafny code (e.g. caches).
- **`Std.Statistics`** — verified statistical functions: sum, mean, median,
  mode, range, variance, and standard deviation.
- **`Std.LocalDateTime`** and **`Std.ZonedDateTime`** — timezone-agnostic and
  timezone-aware date/time types with creation, parsing (ISO 8601),
  arithmetic, formatting, and comparison.
- **`Std.Duration`** — time intervals with millisecond precision, ISO 8601
  duration parsing/formatting, and overflow-safe arithmetic.
