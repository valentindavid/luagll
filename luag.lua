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

u = require("gll.utils")
require("gll.generator")
require("gll.loader")
require("gll.normalize")

local opt = u.opt
local list = u.list
local kw = u.kw
local t = u.t
local range = u.range

local rules =
   {chunk = { { opt(list("stat", opt(t(";")))),
                opt("laststat", opt(t(";"))), cons="chunk" } },

    block = { { "chunk", cons="block" } },

    stat = { { "varlist", kw("="), "explist", cons="init" },
             { "functioncall" },
             { kw("do"), "block", kw("end"), cons="do" },
             { kw("while"), "exp", kw("do"), "block", kw("end"), cons="while" },
             { kw("repeat"), "block", kw("until"), kw("end"), cons="repeat" },
             { kw("if"), "exp", kw("then"), "block",
               opt(list(kw("elseif"), "exp", kw("then"), "block")),
               opt(kw("else"), "block"),
               kw("end"), cons="if" },
             { kw("for"), "Name" , kw("="), "exp", t(","), "exp",
               opt(t(","), exp), kw("do"), "block", kw("end"),
               cons="for" },
             { kw("for"), "namelist" , kw("in"), "explist",
               "block", kw("end"),
               cons="forin" },
             { kw("function"), "funcname", "funcbody",
               cons="function1" },
             { kw("local"), kw("function"), "Name", "funcbody",
               cons="localfunction"},
             { kw("local"), "namelist", opt(kw("="), "explist"),
               cons="local" }
          },

    laststat = { { kw("return"), opt("explist"), cons="return" },
                 { kw("break"), cons="break" }
              },
               
    funcname = { { "Name", opt(list(t("."), "Name")), opt(t(":"), "Name"), cons="funcname" } },

    varlist = { { "var", opt(list(t(","), "var")), cons="varlist"} },

    var =  { { "Name", cons="var" },
             { "prefixexp", t("["), "exp", t("]"), cons="index"},
             { "prefixexp", t("."), "Name", cons="field" }
          },

    namelist = { { "Name", opt(list(t(","), "Name")) , cons="namelist"} },

    explist = { { opt(list("exp", t(","))), "exp", cons = "explist" } },

    exp = { { kw("nil"), cons="nil" },
            { kw("false"), cons="false" },
            { kw("true"), cons="true" },
            { "Number", cons="Number" },
            { "String", cons="String" },
            { kw("..."), cons="dotdotdot" },
            { "function", cons="fun" },
            { "prefixexp" , cons="prefix"},
            { "tableconstructor", cons="tabcons"},
            { "exp", "binop", "exp", cons="binary" },
            { "unop", "exp", cons="unary" } },

    prefixexp = { { "var", cons="prefixvar" },
                  { "functioncall", cons="call" },
                  { t("("), "exp", t(")") }, cons="parenthesis" },

    functioncall =  { { "prefixexp", "args", cons="call" },
                      { "prefixexp", t(":"), "Name", "args", cons="methodcall" } },


    args = { { t("("), opt("explist"), t(")"), cons="arglist" },
             { "tableconstructor", cons="tablearg" },
             { "String", cons="stringarg" },
          },

    ["function"] = { { kw("function"), "funcbody", cons="function2" } },

    funcbody = { { t("("), opt("parlist"), t(")"), "block", kw("end"), cons="body" } },

    parlist = { { "namelist", opt(t(","), t("...")), cons="parlist" },
                { kw("..."), cons="dotdotdot2" } },

    tableconstructor = { { t("{"), opt("fieldlist"), t("}"), cons="tablecons" } },

    fieldlist = { { "field", opt(list("fieldsep", "field")), opt("fieldsep") } },

    field = { { t("["), "exp", t("]"), kw("="), "exp" },
              { "Name", kw("="), "exp" },
              { "exp" } },

    fieldsep = { { t(","), t(";") } },

    binop = { { t("+"), cons="+" },
              { t("-"), cons="-" },
              { t("*") , cons="*" },
              { t("/"), cons="/" },
              { t("^"), cons="^" },
              { t("%"), cons="%" },
              { kw(".."), cons=".." },
              { t("<"), cons="<" },
              { kw("<="), cons="<=" },
              { t(">"), cons=">" },
              { kw(">="), cons=">=" },
              { kw("=="), cons="==" },
              { kw("~="), cons="~=" },
              { kw("and"), cons="and" },
              { kw("or"), cons="or" }
           },

    unop = { { t("-") },
             { kw("not") },
             { t("#") } }
 }

gll.normalize.normalize(rules)

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
--print_table(rules, 0)

gll.normalize.add_layout(rules, "layout")

local lexical_rules =
   { letter = u.range("a", "z"),

     cletter = u.range("A", "Z"),

     idfchar = {{"letter", cons="letter"}, {"cletter", cons="cletter"}, {u.t("_"), cons="underscore"}},

     digit = u.range("0", "9"),

     idchar = {{"idfchar"}, {"digit"}},

     idchars = {{"idchar", "idchars"},
                {cons="emptyidchars"}},

     Name = {{"idfchar", "idchars", cons="Name"}},

     af = range("a", "f"),
     AF = range("A", "F"),

     hexdigit = { { "digit" },
                  { "af" },
                  { "AF" } },

     octdigit = range("0", "7"),

     special_character = { { t("a") },
                           { t("b") },
                           { t("f") },
                           { t("n") },
                           { t("r") },
                           { t("t") },
                           { t("v") },
                           { t("\\") },
                           { t("\"") },
                           { t("\'") },
                           { t("\n") },
                           { t("x"), "hexdigit", "hexdigit" },
                           { "octdigit", "octdigit", "octdigit" },
                           { t("0") }
                        },

     stringcharrange1 = range("\x20", "\x21"),
     stringcharrange2 = range("\x23", "\x2B"),
     stringcharrange3 = range("\x2D", "\x5B"),
     stringcharrange4 = range("\x5D", "\x7E"),

     stringchar = { { "stringcharrange1" },
                    { "stringcharrange2" },
                    { "stringcharrange3" },
                    { "stringcharrange4" },
                    { t("\\"), "special_character" }
                 },

     stringchars = { { "stringchar", "stringchars" },
                     { } },

     String = { { t("\""), "stringchars", t("\"") },
                { t("\'"), "stringchars", t("\'") },
             },

     hexdigits = { { "hexdigit", "hexdigits" }, {} },
     hex_number = { { t("0"), t("x"), "hexdigits" } },

     expletter = { {t("E")}, {t("e")} },
     unum = { { "digit", "unum_aux"} },
     unum_aux = { { "unum" }, {} },
     num = { { t("-"), "unum" }, { "unum" } },

     expn = { { "expletter", "num" }, {} },

     fract = { { t("."), "unum_aux" } },
     optfract = { { "fract" }, {} },

     udec_number = { { "fract", "expn" },
                     { "unum", "optfract", "expn" } },

     dec_number = { { "udec_number" }, { t("-"), "udec_number" } },

     Number = { { "dec_number" }, { "hex_number" } },

     layout = {{"LAYOUT", "layout", cons="layout"}, {}},
     LAYOUT = {{u.t(" ")}, {u.t("\n")}, {u.t("\r")}, {u.t("\t")}, {u.t("\v")}}
  }

for name, rule in pairs(lexical_rules) do
   rules[name] = rule
end

rules.S = { { "layout", "chunk", "layout" } }

-- local consn = 1
-- for name, rule in pairs(rules) do
--    for _, v in ipairs(rule) do
--       if v.cons ~= "layout" then
--          v.cons = (v.cons or "nocons_") .. consn
--          consn = consn + 1
--       end
--    end
-- end

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

local input = { string.rep("local function fibo(a) if a == 0 then return 1 elseif a == 1 then return 1 else return fibo(a-1) + fibo(a+1) end end ", 100) }

local keywords =
   {
   ["and"] = true,
   ["break"] = true,
   ["do"] = true,
   ["else"] = true,
   ["elseif"] = true,
   ["end"] = true,
   ["false"] = true,
   ["for"] = true,
   ["function"] = true,
   ["if"] = true,
   ["in"] = true,
   ["local"] = true,
   ["nil"] = true,
   ["not"] = true,
   ["or"] = true,
   ["repeat"] = true,
   ["return"] = true,
   ["then"] = true,
   ["true"] = true,
   ["until"] = true,
   ["while"] = true
  }

local keyword_cons = {}
for k, v in pairs(keywords) do
   keyword_cons["kw_"..k] = v
end

local function parsed(node)
  if #node >= 2 then
      if node[2].cons == "layout" then
         if node[1].startp == node[1].endp then
            return false
         end
      end
   end
   for i=2, #node-1 do
      if node[i].cons == "layout" then
         if node[i+1].startp == node[i+1].endp then
            return false
         end
      end
   end
   if node.cons == "layout" then
      local la = string.sub(input[1], node.endp+1, node.endp+1)
      if la == " " or la == "\n" or la == "\r" or la == "\t" or la == "\n" or la == "\t" then
	 return false
      end
   elseif node.cons == "Name" then
      if keywords[string.sub(input[1], node.startp+1, node.endp)] then
         --print(string.sub(input[1], node.startp+1, node.endp))
         return false
      end
      local la = string.sub(input[1], node.endp+1, node.endp+1)
      if la and string.len(la) > 0 then
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
   elseif node.cons and keyword_cons[node.cons] then
      local la = string.sub(input[1], node.endp+1, node.endp+1)
      if la and string.len(la) > 0 then
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
   elseif node.cons == "kw_=" then
      local la = string.sub(input[1], node.endp+1, node.endp+1)
      if la == "=" then
         return false
      end
   end

   local ret = { startp = node.startp,
        	 endp = node.endp,
        	 cons = node.cons }
   if node.cons == "Name" then
      ret[1] = {cons=string.sub(input[1], node.startp+1, node.endp)}
      if keywords[ret[1].cons] then
         return false
      end
   elseif node.cons == "Number" then
      ret[1] = {cons=string.sub(input[1], node.startp+1, node.endp)}
   elseif node.cons == "String" then
      ret[1] = {cons=string.sub(input[1], node.startp+1, node.endp)}
   -- elseif node.cons == "Conc" then
   --    ret.cons = "List"
   --    for i=1, #(node[1]) do
   --       table.insert(ret, node[1][i])
   --    end
   --    table.insert(ret, node[3])
   else
   --end
      for i=1, #node do
         if node[i].cons ~= "layout" then
            ret[#ret+1] = node[i]
         end
      end
   end
   --dump(ret)
   --io.write("\n")
   return true, ret
   --return node
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
      --dump(returned_nodes)
      io.write("\n")
      if done then
	 error("Ambiguous")
      end
      done = true
   end
end

local stack = { { [2] = finished }, found = {} }
local before = os.clock()
parser(stack, input)
print (os.clock() - before)
