require 'DataDumper'

local luif = {
  G = function(grammar) return grammar end,
  S = function(name) return "S:'" .. name .. "'" end,
  L = function(literal) return "L'" .. literal .. "'" end,
  C = function(charclass) return "C'" .. charclass .. "'" end,
  Q = function(quantifier) return "Q'" .. quantifier .. "'" end,
}

local S = luif.S
local L = luif.L
local C = luif.C
local Q = luif.Q

local pow = function (...) local arg={...} return arg[1] ^ arg[2] end
local mul = function (e1, e2) return e1 * e2 end
local div = function (...) return arg[1] / arg[2] end
local add = function (...) return arg[1] + arg[2] end
local sub = function (...) return arg[1] - arg[2] end

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
  Number = C'[0-9]+'
}

print(DataDumper(calc))