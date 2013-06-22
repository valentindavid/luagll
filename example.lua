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

u = require "gll.utils"
require "gll.generator"
require "gll.loader"

local rules = {S = {{"Identifiers", "layout", cons="Start"}},
	 Identifiers = {{"Identifiers", "layout", "IDorKeyword", cons="Conc"},
			{cons="Nil"}},
	 letter = u.range("a", "z"),
	 cletter = u.range("A", "Z"),
	 idfchar = {{"letter"}, {"cletter"}, {u.t("_")}},
	 digit = u.range("0", "9"),
	 idchar = {{"idfchar"}, {"digit"}},
	 idchars = {{"idchar", "idchars"},
		    {}},
         Keyword = {u.keyword("foo"),u.keyword("bar")},
         IDorKeyword = {{"ID"}, {"Keyword", cons="Keyword"}},
	 ID = {{"idfchar", "idchars", cons="ID"}},
	 layout = {{"LAYOUT", "layout", cons="layout"}, {}},
	 LAYOUT = {{u.t(" ")}, {u.t("\n")}, {u.t("\r")}, {u.t("\t")}}
      }

local function dump(table, indent, traversed)
   if not traversed then
      traversed = {}
   end
   if traversed[table] then
      assert(false)
   end
   traversed[table] = true
   if not indent then
      indent = 0
   end
   if table.cons then
      io.write(table.cons)
      indent = indent + #(table.cons)
   end
   indent = indent + 1
   if #table > 0 then
      io.write("(")
      for i=1, #table do
	 dump(table[i], indent, traversed)
	 io.write("\n")
	 io.write(string.rep(" ", indent))
      end
      io.write(")")
   end
   if table.startp or table.endp then
      io.write("[")
      io.write(tostring(table.startp))
      io.write("-")
      io.write(tostring(table.endp))
      io.write("]")
   end
end

local input = { string.rep(" a dewq dwqmjwdqojidwqji j barx bar foo ffoo iowdq ji foo dwfoooiqjdw jp   ", 10) }

local function parsed(node)
   if node.cons == "layout" then
      local la = string.sub(input[1], node.endp+1, node.endp+1)
      if la == " " or la == "\n" or la == "\r" or la == "\t" then
	 return false
      end
   elseif node.cons == "ID" or node.cons == "Keyword" then
      local la = string.sub(input[1], node.endp+1, node.endp+1)
      if string.len(la) > 0 then
	 local bla = string.byte(la)
	 if bla >= string.byte("a") and bla <= string.byte("z") then
	    return false
	 end
	 if bla >= string.byte("A") and bla <= string.byte("Z") then
	    return false
	 end
	 if bla >= string.byte("0") and bla <= string.byte("9") then
	    return false
	 end
	 if bla == string.byte("_") then
	    return false
	 end
      end
   end
   local ret = { startp = node.startp,
		 endp = node.endp,
		 cons = node.cons }
   if node.cons == "ID" then
      ret[1] = {cons=string.format("%q", string.sub(input[1], node.startp+1, node.endp))}
      if ret[1].cons == "\"foo\"" or ret[1].cons == "\"bar\"" then
         return false
      end
   elseif node.cons == "Conc" then
      ret.cons = "List"
      for i=1, #(node[1]) do
	 ret[#ret+1] = node[1][i]
      end
      ret[#ret+1] = node[3]
   else
      for i=1, #node do
	 if node[i].cons ~= "layout" then
	    ret[#ret+1] = node[i]
	 end
      end
   end
   return true, ret
end

local function get(pos, stream, endp)
   if not endp then
      endp = pos
   end
   if pos < #(stream[1]) then
      return string.sub(stream[1], 1+pos, 1+endp)
   else
      return nil
   end
end

local tmp = io.open("tmp.lua", "w")
gll.generator.generate(rules, tmp)
tmp:close()
local parser = gll.loader.load_grammar("tmp.lua", {parsed = parsed, get = get})


local done = false
local function finished(stack, la, i, stream, returned_nodes)
   if (la == nil) then
      dump(returned_nodes)
      io.write("\n")
      if done then
	 error("Ambiguous")
      end
      done = true
   end
end

local stack = { { [2] = finished }, found = {} }
parser(stack, input)
