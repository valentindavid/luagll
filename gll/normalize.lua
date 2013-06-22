-- Copyright 2013  Valentin David

-- This file is part of Luagll.

-- Luagll is free software: you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- Luagll is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

local pairs = pairs
local string = string
local ipairs = ipairs
local type = type
local table = table
local error = error
local assert = assert

module "gll.normalize"

local function normalize_symbol(rules, sym, anon)
   local ret = sym
   if type(sym) == "string" then
      return assert(sym)
   elseif sym.type == "opt" then
      local sym = normalize_symbol(rules, sym[1], anon)
      ret = sym .. "_opt"
      if not rules[ret] then
         rules[ret] = {{sym, cons="Opt"}, {cons = "None"}}
      end
   elseif sym.type == "list" then
      local sym = normalize_symbol(rules, sym[1], anon)
      ret = sym .. "_list"
      local aux = ret .. "_aux"
      if not rules[ret] then
         rules[ret] = {{sym, aux, cons="Conc"}}
      end
      if not rules[aux] then
         rules[aux] = {{ret, cons="List"}, {cons="Nil"}}
      end
   elseif sym.type == "list_sep" then
      local sym = normalize_symbol(rules, sym[1], anon)
      local sep_sym = normalize_symbol(rules, sym[2], anon)
      ret = sym .. "_list_sep_" .. sep_sym
      local aux = ret .. "_aux"
      if not rules[ret] then
         rules[ret] = {{sym, aux}}
      end
      if not rules[aux] then
         rules[aux] = {{sep_sym, ret}, {}}
      end
   elseif sym.type == "anonymous" then
      for _, w in ipairs(sym[1]) do
         for j, x in ipairs(w) do
            w[j] = normalize_symbol(rules, x, anon)
         end
      end
      ret = string.format("anon_%d", anon[1])
      anon[1] = anon[1] + 1
      rules[ret] = sym[1]
   elseif (not sym.type) and #sym == 1 and type(sym[1]) == "string" then
   else
      error("Unexpected type")
   end
   return assert(ret)
end

function normalize(rules)
   local anon = { 1 }
   local copy = {}
   for name, rule in pairs(rules) do
      copy[name] = rule
   end
   for name, rule in pairs(copy) do
      for k, r in ipairs(rule) do
         for i, v in ipairs(r) do
            r[i] = normalize_symbol(rules, v, anon)
         end
      end
   end
end

function add_layout(rules, symbol)
   for name, rule in pairs(rules) do
      for _, r in ipairs(rule) do
         if not r.lexical then
            for i=#r,2,-1 do
               table.insert(r, i, symbol)
            end
         end
      end
   end
end
