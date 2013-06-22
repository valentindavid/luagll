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

local string = string
local table = table
local type = type
local error = error
local ipairs = ipairs

local print = print
local pairs = pairs
local tostring = tostring

module "gll.utils"

function t(name)
   if type(name) ~= "string" then
      error("Parameter should be a string")
   end
   return {name}
end

function is_terminal(n)
   return type(n) == "table"
end

function get_terminal(n)
   return n[1]
end

function range(from, to)
   local ret = {}
   for i=string.byte(from),string.byte(to) do
      table.insert(ret, {t(string.char(i))})
   end
   return ret
end

function keyword(str)
   if type(str) ~= "string" then
      error("Unexpected type")
   end
   local ret = { lexical = true }
   for i=1, string.len(str) do
      table.insert(ret, t(string.sub(str, i, i)))
   end
   return ret
end

local function check(...)
   for _, v in ipairs({...}) do
      if type(v) == "string" then
      elseif type(v) == "table" then
         if not v.type then
            if #v ~= 1 or type(v[1]) ~= "string" then
               error("Unexpected type")
            end
         end
      else
         error("Unexpected type")
      end
   end
end


function list(...)
   check(...)
   return {type="list", inl({{...}})}
end

function opt(...)
   check(...)
   return {type="opt", inl({{ ... }})}
end

function choice(...)
   check(...)
   return inl({...})
end

local function print_table(t, indent)
   if type(t) ~= "table" then
      print(string.rep(" ", indent) .. tostring(t))
   else
      for q,w in pairs(t) do
         print(string.rep(" ", indent) .. tostring(q))
         print_table(w, indent + 2)
      end
   end
end

function inl(rule)
   return {type="anonymous", rule}
end

function kw(str)
   if type(str) ~= "string" then
      error("Unexpected type")
   end
   local t = keyword(str)
   t.cons = "kw_" .. str
   return inl({t})
end
