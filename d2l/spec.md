﻿# LUIF Direct-to-Lua (D2L, d2l) calls

This is a write-up on defining LUIF BNF statements as first-class Lua objects along the lines of [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html#intro).

To quote Roberto:

> Following the Snobol tradition, LPeg defines patterns as first-class objects. That is, patterns are regular Lua values (represented by userdata). The library offers several functions to create and compose patterns. With the use of metamethods, several of these functions are provided as infix or prefix operators. On the one hand, the result is usually much more verbose than the typical encoding of patterns using the so called regular expressions (which typically are not regular expressions in the formal sense). On the other hand, first-class patterns allow much better documentation (as it is easy to comment the code, to break complex definitions in smaller parts, etc.) and are extensible, as we can define new functions to create and compose patterns.

## Calculator Grammar

### LUIF

```
Script ::= Expression+ % ','
Expression ::=
  Number
  | '(' Expression ')'
 || Expression '**' Expression, action = function (...) return arg[1] ^ arg[2] end
 || Expression '*' Expression, action = function (...) return arg[1] * arg[2] end
  | Expression '/' Expression, action = function (...) return arg[1] / arg[2] end
 || Expression '+' Expression, action = function (...) return arg[1] + arg[2] end
  | Expression '-' Expression, action = function (...) return arg[1] - arg[2] end
 Number ~ [0-9]+
```

### Direct-to-Lua

```lua
local calc = luif.G{
  Script = { S'Expression', Q'+', '%', L',' },
  Expression = {
    { S'Number' },
    { '|' , '(', S'Expression', ')' },
    { '||', S'Expression', L'**', S'Expression', { action = pow } },
    { '||', S'Expression', L'*', S'Expression', { action = mul } },
    { '|' , S'Expression', L'/', S'Expression', { action = div } },
    { '||', S'Expression', L'+', S'Expression', { action = add } },
    { '|' , S'Expression', L'-', S'Expression', { action = sub } },
  },
  Number = C'[0-9]'
}
```

Notes:

    1. See `calc.lua` for the complete example.

    2. A lexical rule `Number = C'[0-9]'` can be inferred by checking that its RHS contains only literals, charclasses and LHSes of rules having only literals and charclasses on their RHSes.

[Warning: very early draft below]

## Interface

An outline of D2L functions to be used to build
a Lua table containing LUIF rules for KHIL.

s = symbol ('name')
r = rule (lhs, alternative1, alternative2, ... )

a = alternative ( rhs1, rhs2, ..., { adverbs })

pa = alternative ( rhs1, rhs2, ..., { precedence = '|', action = function })

s = alternative ( item, separator, { quantifier = '+', proper = true } )
s = alternative ( item, separator, { quantifier = '*', proper = false } )

-- adverb setters

ha = hide (alternative1, alternative2, ...)
ga = group (alternative1, alternative2, ...)
la = loosen (alternative)
ta = tighten (alternative)
ca = count (alternative, quantifier, proper) -- item, separator
aa = actify (alternative, function(...) end )

l = literal('string')
c = charclass('[a-z]') --

adverbs
  hidden      true, false
  group       true, false
  proper      true, false
  action      function, descriptor(s)
  quantifier  '+', '*'
  precedence  '|', '||'
  lexical     true, false

## External Grammar (LUIF Rules) for KHIL

D2L will build
a Lua table of LUIF rules (can be based on SLIF MetaAST)
to be passed to KHIL
for conversion to KIR.

{
  {
    lhs = 'Expression'
    rhs = {}
    adverbs = {
      action = function(...) end
      priority = '|'
      lexical =
    },
  },

  {
    lhs = 'Script',
    rhs = { 'Expression',  },
    adverbs = {
      action = function(...) end
      quantifier =                  -- '+' or '*'
      proper = true                 -- true or false
    },
  },

  {
    lhs = 'Lex-1',
    rhs = { ',' }
    adverbs = {
      lexical = true
    },
  }

  {
    lhs = 'Number'
    rhs = {}
    adverbs = {
      lexical = true
    },
  },

}