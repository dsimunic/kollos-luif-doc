﻿# The LUIF

This document (which is currently a work-in-progress) describes the LUIF (LUa InterFace),
the interface language of
the [Kollos project](https://github.com/jeffreykegler/kollos/).

The LUIF is [Lua](http://www.lua.org/), extended with [BNF](http://en.wikipedia.org/wiki/Backus%E2%80%93Naur_Form) statements.

[todo: a (link to) a brief BNF introduction/tutorial?]

## Table of Contents

[BNF Statement](#bnf_statement)<br/>
- [Structural and Lexical Rules](#structural_and_lexical_rules)<br/>
- [Grammars](#grammars)<br/>
- [Precedenced Rules](#precedenced_rules)<br/>
- [Sequences](#sequences)<br/>
- [Grouping and Hiding Symbols](#grouping_and_hiding_symbols)<br/>
- [Symbol Names](#symbol_names)<br/>
- [Literals](#literals)<br/>
- [Character Classes](#character_classes)<br/>
- [Comments](#comments)<br/>
- [Adverbs](#adverbs)<br/>
  - [`action`](#action)<br/>
  - [`completed`](#completed)<br/>
  - [`predicted`](#predicted)<br/>
  - [`assoc`](#assoc)

[Semantics](#semantics)<br/>
- [Defining Semantics with `action` adverb](#defining_semantics_with_action_adverb)<br/>
- [Context Accessors](#context_accessors)<br/>

[Events](#events)<br/>
[Post-Processing](#post_processing)<br/>
[Programmatic Grammar Construction](#programmatic_grammar_construction)<br/>
[Locale Support](#locale_support)<br/>
[Complete Syntax of BNF Statement](#complete_syntax_of_bnf_statement)<br/>
[Example Grammars](#example_grammars)<br/>
- [Calculator](#calculator)<br/>
- [JSON](#json)<br/>

<a id="bnf_statement"></a>
## BNF Statement

LUIF extends the Lua syntax by adding `bnf` alternative to `stat` rule of the [Lua grammar](http://www.lua.org/manual/5.1/manual.html#8) and introducing the new rules for BNF statements. There is only one BNF statement, combining [precedence](#precedenced_rules),
[sequences](#sequences), and alternation as specified below.

A BNF statement specifies a rule, which consists of, in order:

- A left hand side (LHS), which will be a [symbol](#symbol_names).

- A produce-operator (`::=` or `~`).

- A right-hand side (RHS), which contains one or more RHS alternatives.

<a id="structural_and_lexical_rules"></a>
### Structural and Lexical Rules

A rule specified by a BNF statement can be either structural or lexical.

[todo: specify how lexemes are defined ]

<a id="grammars"></a>
## Grammars

BNF statements are grouped into one or more grammars.  There are two kinds of LUIF grammars: structural and lexical.

A grammar is lexical if one or more of its rules have the special `lexeme` action.
[todo: specify `lexeme` action]

The grammar is indicated by the produce-operator of the BNF. Its general form is `:grammar:=`, where `grammar` is the name of a grammar.  `grammar` must not contain colons.  Initially, the [post-processing](#post_processing) will not support anything but `l0` and `g1` used in the default way, like this:

```lua
-- structural grammar
a ::= b c       -- the first rule is the start rule
                -- using the LHS (b c) of a lexical rule
                -- on the RHS of a structural rule makes a lexeme
a ::= w
aa ::= a a

-- lexical grammar
w ~ x y z
b ~ 'b' x
c ~ 'c' y

x ~ 'x'
y ~ 'y'
z ~ [xyz]

```

If the produce-operator is `::=`, then the grammar is `g1`.  The tilde `~` can be a produce-operator, in which case it is equivalent to `:l0:=`.

A structural grammar will often contain lexical elements, such as strings and character classes, and these will go into its linked lexical grammar.  The start rule specifies its lexical grammar with an adverb (what?).  In a lexical grammar the lexemes are indicated with the `lexeme` adverb -- if a rule has a lexeme adverb, its LHS is a lexeme.

If a grammar specifies lexemes, it is a lexical grammar.  If a grammar specifies a linked lexical grammar, it is a structural grammar.  `l0` must always be a lexical grammar.  `g1` must always be a structural grammar and is linked by default to `l0`.  It is a fatal error if a grammar has no indication whether it is structural or lexical, but this indication may be a default.  Enforcement of these restrictions is done by the lower layer (KLOL).

[under discussion: https://github.com/rns/kollos-luif-doc/issues/10]

[TBD]

<a id="precedenced_rules"></a>
### Precedenced Rules

[TBD]

<a id="sequences"></a>
### Sequences

Sequences are expressions on the RHS of a BNF rule alternative
which imply the repetition of a symbol,
or a parenthesized series of symbols. The general syntax for sequences is

[todo: add sequence snippet from the LUIF grammar ]
```
```

The item to be repeated (the repetend)
can be either a single symbol,
or a sequence of symbols grouped by
parentheses or square brackets,
as described above.
A repetition consists of

+ A repetend, followed by
+ An optional punctuation specifier.

A repetition specifier is one of

```
    ** N..M     -- repeat between N and M times
    ** N..*     -- repeat more than N times
    ?           -- equivalent to ** 0..1
    *           -- equivalent to ** 0..*
    +           -- equivalent to ** 1..*
```

A punctuation specifier is one of
```
    % <sep>     -- use <sep> as a proper separator
    %% <sep>     -- use <sep> as liberal separator
    %- <sep>    -- proper separation, same as %
    %$ <sep>    -- use <sep> as a terminator
```
When proper separation is in use,
the separators must actually separate items.
A separator after the last item is not allowed.

When the separator is used as a terminator,
it must come after every item.
In particular, there *must* be a separator
after the last item.

A "liberal" separator may be used either
as a proper separator or a terminator.
That is, the separator after the last item
is optional.

Here are some examples:

```
    A+                 -- one or more <A> symbols
    A*                 -- zero or more <A> symbols
    A ** 42            -- exactly 42 <A> symbols
    <A> ** 3..*        -- 3 or more <A> symbols
    <A> ** 3..42       -- between 3 and 42 <A> symbols
    (<A> <B>) ** 3..42 -- between 3 and 42 repetitions of <A> and <B>
    [<A> <B>] ** 3..42 -- between 3 and 42 repetitions of <A> and <B>,
                       --   hidden from the semantics
    <a>* % ','         -- 0 or more properly comma-separated <a> symbols
    <a>+ % ','         -- 1 or more properly comma-separated <a> symbols
    <a>? % ','         -- 0 or 1 <a> symbols; note that ',' is never used
    <a> ** 2..* % ','  -- 2 or more properly comma-separated <a> symbols
    <A>+ % ','         -- one or more properly comma-separated <A> symbols
    <A>* % ','         -- zero or more properly comma-separated <A> symbols
    (A B)* % ','       -- A and B, repeated zero or more times, and properly comma-separated
    <A>+ %% ','        -- one or more comma-separated or comma-terminated <A> symbols

```

The repetend cannot be nullable.
If a separator is specified, it cannot be nullable.
If a terminator is specified, it cannot be nullable.
If you try to work out what repetition of a nullable item actually means,
I think the reason for these restrictions will be clear --
such a repetition is very ambiguous.
An application which really wants to specify rules involving nullable repetition,
can specify them directly in BNF,
and these will make the programmer's intent clear.

<a id="grouping_and_hiding_symbols"></a>
### Grouping and hiding symbols

To group a series of RHS symbols use parentheses:

```
   ( A B C )
```

You can also use square brackets,
in which case the symbols will be hidden
from the semantics:

```
   [ A B C ]
```

Parentheses and square brackets can be nested.
If square brackets are used at any nesting level
containing a symbol, that symbol is hidden.
In other words,
there is no way to "unhide" a symbol that is inside
square brackets.

<a id="symbol_names"></a>
### Symbol names

A LUIF symbol name is any valid Lua name.
Eventually names with non-initial hyphens will be allowed and an angle bracket notation for LUIF symbol names,
similar to that of
the [SLIF](https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod#Symbol-names),
will allow whitespace
in names.

<a id="literals"></a>
### Literals

LUIF literals are Lua literal strings as defined in [Lexical Conventions](http://www.lua.org/manual/5.1/manual.html#2.1) section of the Lua 5.1 Reference Manual.

<a id="character_classes"></a>
### Character classes

A character class is a string, which must contain
a valid [Lua character class](http://www.lua.org/manual/5.1/manual.html#5.4.1) as defined in the Lua reference manual.
Strings can be defined with character classes using sequence rules.

<a id="comments"></a>
### Comments

LUIF comments are Lua comments as defined at the end of [Lexical Conventions](http://www.lua.org/manual/5.1/manual.html#2.1) section in the Lua 5.1 Reference Manual.

<a id="adverbs"></a>
### Adverbs

A LUIF rule can be modified by one or more adverbs, which are `name = value` pairs separated with commas. Comma is also used to separate an adverb from the RHS alternative it modifies.

[todo: example]

<a id="action"></a>
#### `action`

The `action` adverb defines the semantics of the RHS alternative it modifies.
Its value is specified in [Semantics](#semantics) section below.

<a id="completed"></a>
#### `completed`

The `completed` adverb defines
the Lua function to be called when the RHS alternative is completed during the parse.
Its value is the same as that of the `action` adverb.

For more details on parse events, see [Events](#events) section.

<a id="predicted"></a>
#### `predicted`

The `predicted` adverb defines
the Lua function to be called when the RHS alternative is predicted during the parse.
Its value is the same as that of the `action` adverb.

For more details on parse events, see [Events](#events) section.

<a id="assoc"></a>
#### `assoc`

The `assoc` adverb defines associativity of a [precedenced rule](#precedenced_rules).
Its value can be `left`, `right`, or `group`.
The function of this adverb is as defined in the [SLIF](https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod#assoc).

For a usage example, see the [Calculator](#calculator) grammar below.

<a id="semantics"></a>
## Semantics

The semantics of a BNF statement in the LUIF can be defined using [`action` adverb](#defining_semantics_with_action_adverb) of its RHS alternative.

<a id="defining_semantics_with_action_adverb"></a>
### Defining Semantics with `action` adverb

The value of the `action` adverb can be a body of a Lua function (`funcbody`) as defined in [Function Definitions](http://www.lua.org/manual/5.1/manual.html#2.5.9) section of the Lua 5.1 Reference Manual or the name of such function, which must be a bare name (not a namespaced or a method function's name).

The action functions will be called in the context where their respective BNF statements are defined. Their return values will become the values of the LHS symbols corresponding to the RHS alternatives modified by the `action` adverb.

The match context information, such as
matched rule data, input string locations and literals
will be provided by [context accessors](#context_accessors) in `luif.context` namespace.

If the semantics of a BNF statement is defined in a separate Lua file, LUIF functionality must be imported with Lua's [`require`] (http://www.lua.org/manual/5.1/manual.html#pdf-require) function.

The syntax for a semantic action function is

```lua
action = function (params) body end
```

It will be called as `f (params)`
with `params` set to
the values defined by the semantics of the matched RHS alternative's symbols.

[parameter list is under discussion at https://github.com/rns/kollos-luif-doc/issues/26]

<a id="context_accessors"></a>
#### Context Accessors

Context accessors live in the `luif.context` name space.
They can be called from semantic actions to get matched rule and locations data.
To import them into a separate file, use Lua's [`require`](http://www.lua.org/manual/5.1/manual.html#pdf-require) function, i.e.

```lua
require 'luif.context'
```

The context accessors are:

##### `lhs_id = luif.context.lhs()`

returns the integer ID of the symbol which is on the LHS of the BNF rule matched in the parse value or completed/predicted during the parse.

##### `rule_id = luif.context.rule()`

returns the integer ID of the BNF rule matched in the parse value or completed/predicted during the parse.

##### `alt_no = luif.context.alternative()`

returns the number of the BNF rule's RHS alternative matched in the parse value or completed/predicted during the parse.

##### `prec = luif.context.precedence()`

returns numeric precedence of the matched/completed/predicted alternative
relative to other alternatives or nil if no precedence is defined for the alternative.

##### `pos, len = luif.context.span()`

returns position and length of the input section corresponding to
the BNF rule matched in the parse value or
completed/predicted during the parse.

##### `string = luif.context.literal()`

returns the section of the input corresponding to
the BNF rule matched in the parse value or
completed/predicted during the parse.
It is defined by
the input span returned by the `luif.context.span()` function above.

##### `pos = luif.context.pos()`

returns the position in the input, which starts the span corresponding to
the BNF rule matched in the parse value or
completed/predicted during the parse.

##### `len = luif.context.length()`

returns the length of the input span corresponding to
the BNF rule matched in the parse value or
completed/predicted during the parse.

<a id="events"></a>
## Events

Parse events are defined using [`completed`](#completed) and [`predicted`](#predicted) adverbs.

[todo: provide getting started info/tutorial on parse events].

<a id="post_processing"></a>
## Post-processing

LUIF grammars are transformed into KIR (Kollos Intermediate Runtime) tables using Direct-to-Lua (D2L) calls and format specified in a [separate document](d2l/spec.md).

The output will be a table, with one key for each grammar name.  Keys *must* be strings.  The value of each grammar key will be a table, with entries for external and internal symbols and rules.  Details of the format will be specified later.

The KIR table will be interpreted by the lower layer (KLOL).  Initially post-processing will take a very restricted form in the LUIF structural and lexical grammars.

The post-processing will expect a lexical grammar named `l0` and a structural grammar named `g1`, and will check (in the same way that Marpa::R2 currently does) to ensure they are compatible.

<a id="programmatic_grammar_construction"></a>
## Programmatic Grammar Construction (PGC)

Direct-to-Lua (D2L) calls can be used to build LUIF grammars programmatically.
The details are specified in a [separate document](d2l/spec.md).

At the moment, LUIF statements cannot be affected by Lua statements directly,
but this can change in future.

<a id="locale_support"></a>
## Locale support

Full support is only assured for the "C" locale -- support for other locales may be limited, inconsistent, or removed in the future.

Lua's `os.setlocale()`, when used in the LUIF context for anything but the "C" locale, may fail, silently or otherwise.

[todo: update the tentative language above as Kollos project progresses]

<a id="complete_syntax_of_bnf_statement"></a>
## Complete Syntax of BNF Statement

The general syntax for a BNF statement is as follows (`stat`, `block`, `funcbody`, `Name`, and `String` symbols are as defined by the Lua grammar):

Note: this describes LUIF structural and lexical grammars 'used in the default way' as defined in [Grammars](#grammars) section below. The first rule will act as the start rule.

[todo: make sure it conforms to other sections]

```
stat ::= bnf

bnf ::= lhs produce_op rhs  -- to make references to LHS/RHS easier to understand

lhs ::= symbol_name

produce_op ::= '::=' |
               '~'

rhs ::= precedenced_alternative { '||' precedenced_alternative }

precedenced_alternative ::= alternative { '|' alternative }

alternative ::= rhslist { ',' adverb }

adverb ::= action |
           completed |
           predicted |
           assoc

-- values other than function(...) -- https://github.com/rns/kollos-luif-doc/issues/12
-- context in action functions -- https://github.com/rns/kollos-luif-doc/issues/11
action ::= 'action' '=' functionexp

completed ::= 'completed' '=' functionexp

predicted ::= 'predicted' '=' functionexp

functionexp ::= 'function' funcbody |
                Name

assoc ::= 'assoc' '=' assocexp

assocexp ::= 'left' |
             'right' |
             'group'

rhslist ::= { rh_atom }       -- can be empty, like Lua chunk

rh_atom ::= separated_sequence |
            symbol_name |
            literal |
            charclass |
            '(' alternative ')' |
            '[' alternative ']'

separated_sequence ::= sequence  |
                       sequence '%'  separator | -- proper separation
                       sequence '%%' separator |
                       sequence '%-' separator |
                       sequence '%$' separator

-- more complex separators -- http://irclog.perlgeek.de/marpa/2015-05-03#i_10538440
separator ::= symbol_name

sequence ::= symbol_name '+' |
             symbol_name '*' |
             symbol_name '?' |
             symbol_name '*' Number '..' Number |
             symbol_name '*' Number '..' '*'

symbol_name :: Name

literal ::= String    -- long strings not allowed

charclass ::= String

```

[todo: implementation detail: Lua patterns can be much slower than regexes, so we can
use lua patterns as they are or
translate them to regexes for speed
or make this an option ]

[todo: nested delimiters as sequence separators,
like [`%bxy`](http://www.lua.org/pil/20.2.html), but with nesting support
per comment to https://github.com/rns/kollos-luif-doc/issues/17]

<a id="example_grammars"></a>
## Example grammars

<a id="calculator"></a>
### Calculator

```
Script ::= Expression+ % ','
Expression ::=
  Number
  | '(' Expression ')', assoc = group, action = do_parens
 || Expression '**' Expression, assoc = right, action = function (e1, e2) return e1 ^ e2 end
 || Expression '*' Expression, action = function (e1, e2) return e1 * e2 end
  | Expression '/' Expression, action = function (e1, e2) return e1 / e2 end
 || Expression '+' Expression, action = function (e1, e2) return e1 + e2 end
  | Expression '-' Expression, action = function (e1, e2) return e1 - e2 end
 Number ~ [0-9]+
```

<a id="json"></a>
### JSON

```

-- structural

json     ::= object
           | array
object   ::= [ '{' '}' ]
           | [ '{' ] members [ '}' ]
members  ::= pair+ % comma
pair     ::= string [ ':' ] value
value    ::= string
           | object
           | number
           | array
           | true
           | false
           | null
array    ::= [ '[' ']' ]
           | [ '[' ] elements [ ']' ]
elements ::= value+ % comma
string   ::= lstring

-- lexical

comma          ~ ','
-- [todo: true and false are Lua keywords: KHIL needs to handle this]
S_true         ~ 'true'
S_false        ~ 'false'
null           ~ 'null'
number         ~ int
               | int frac
               | int exp
               | int frac exp
int            ~ digits
               | '-' digits
digits         ~ [\d]+
frac           ~ '.' digits
exp            ~ e digits
e              ~ 'e'
               | 'e+'
               | 'e-'
               | 'E'
               | 'E+'
               | 'E-'
lstring        ~ quote in_string quote
quote          ~ ["]
in_string      ~ in_string_char*
in_string_char ~ [^"] | '\"'

whitespace     ~ [\s]+

-- [todo: specify equivalent in LUIF ]
:discard       ~ whitespace

```
