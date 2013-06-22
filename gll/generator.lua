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
local pairs = pairs
local ipairs = ipairs
local type = type
local setmetatable = setmetatable
local error = error

local print = print
local tostring = tostring

module "gll.generator"

local debug = true
local Epsilon = {}
local EOF = {}

local function is_terminal(n)
   return type(n) == "table"
end

local function get_terminal(n)
   return n[1]
end

local Properties = {}

local function check(rules)
   if not rules["S"] then
      error "Missing symbol S"
   end
   for name, rule in pairs(rules) do
      for i, r in ipairs(rule) do
         for j, v in ipairs(r) do
            if not is_terminal(v) then
               if not rules[v] then
                  error(string.format("Missing symbol %q", v))
               end
            end
         end
      end
   end
end

function Properties:new(rules)
   local o = {rules = rules,
              props = {}}
   check(rules)
   for name, rule in pairs(rules) do
      o.props[name] = {
         follow = {},
         last_nt = {},
         first = {},
         first_nt = {}
      }
   end
   o.props["S"].follow[EOF] = true
   setmetatable(o, self)
   self.__index = self
   o:analyze()
   return o
end

function Properties:analyze()
   local modified = true
   while modified do
      modified = false
      for aname, a in pairs(Properties.analyzers) do
         for name, rules in pairs(self.rules) do
            for _, rule in ipairs(rules) do
               if a(self.props, name, rule) then
                  modified = true
               end
            end
         end
      end
   end
end

function Properties:left_recursive(name)
   return self.props[name].first_nt[name]
end

Properties.analyzers = {}

function Properties.analyzers.first_nt(props, name, rule)
   local modified = false
   for i, v in ipairs(rule) do
      if is_terminal(v) then
         return modified
      else
         if not props[name].first_nt[v] then
            props[name].first_nt[v] = true
            modified = true
         end
         for k, _ in pairs(props[v].first_nt) do
            if not props[name].first_nt[k] then
               props[name].first_nt[k] = true
               modified = true
            end
         end
         if not props[v].first[Epsilon] then
            return modified
         end
      end
   end
   return modified
end

function Properties.analyzers.first(props, name, rule)
   local modified = false
   for i, v in ipairs(rule) do
      if is_terminal(v) then
         if not props[name].first[get_terminal(v)] then
            props[name].first[get_terminal(v)] = true
            return true
         end
         return modified
      else
         for k, _ in pairs(props[v].first) do
            if not props[name].first[k] then
               props[name].first[k] = true
               modified = true
            end
         end
         if not props[v].first[Epsilon] then
            return modified
         end
      end
   end
   if not props[name].first[Epsilon] then
      props[name].first[Epsilon] = true
      modified = true
   end
   return modified
end

function Properties.analyzers.last_nt(props, name, rule)
   local modified = false
   for i=#rule,1,-1 do
      local v = rule[i]
      if is_terminal(v) then
         return modified
      else
         if not props[name].last_nt[v] then
            props[name].last_nt[v] = true
            modified = true
         end
         for k, _ in pairs(props[v].last_nt) do
            if not props[name].last_nt[k] then
               props[name].last_nt[k] = true
               modified = true
            end
         end
         if not props[v].first[Epsilon] then
            return modified
         end
      end
   end
   return modified
end

function Properties.analyzers.follow(props, name, rule)
   local modified = false
   local before = {}
   for i, v in ipairs(rule) do
      if is_terminal(v) then
         for k, _ in pairs(before) do
            if not props[k].follow[get_terminal(v)] then
               props[k].follow[get_terminal(v)] = true
               modified = true
            end
         end
         before = {}
      else
         for f, _ in pairs(props[v].first) do
            if f ~= Epsilon then
               for k, _ in pairs(before) do
                  if not props[k].follow[f] then
                     props[k].follow[f] = true
                     modified = true
                  end
               end
            end
         end
         if not props[v].first[Epsilon] then
            before = {}
         end
         for k, _ in pairs(props[v].last_nt) do
            before[k] = true
         end
         before[v] = true
      end
   end
   for f, _ in pairs(props[name].follow) do
      for k, _ in pairs(before) do
         if not props[k].follow[f] then
            props[k].follow[f] = true
            modified = true
         end
      end
   end
   return modified
end

function Properties:follow(name)
   return self.props[name].follow
end

function Properties:first(rule)
   local props = self.props
   local ret = {}
   for i, v in ipairs(rule) do
      if is_terminal(v) then
         ret[get_terminal(v)] = true
         return ret
      else
         for t, _ in pairs(props[v].first) do
            ret[t] = true
         end
         if not props[v].first[Epsilon] then
            return ret
         end
      end
   end
   ret[Epsilon] = true
   return ret
end

function Properties:ll_subset(name)
   local ambiguous = {}
   local set = {}
   for i, v in ipairs(self.rules[name]) do
      for a, _ in pairs(self:first(v)) do
         if not ambiguous[a] then
            if set[a] then
               ambiguous[a] = true
               set[a] = nil
            else
               set[a] = true
            end
         end
      end
   end
   return set
end

function Properties:is_ll(name)
   local rules = self.rules
   local l = rules[name]

   if self.props[name].first[Epsilon] then
      for a, _ in pairs(self.props[name].first) do
         if self.props[name].follow[a] then
            return false
         end
      end
      for a, _ in pairs(self.props[name].follow) do
         if self.props[name].first[a] then
            return false
         end
      end
   end

   for i, v in ipairs(l) do
      for j=i+1,#l do
         for a, _ in pairs(self:first(v)) do
            if self:first(l[j])[a] then
               return false
            end
         end
         for a, _ in pairs(self:first(l[j])) do
            if self:first(v)[a] then
               return false
            end
         end
      end
   end
   return true
end

local TestGenerator = {}
function TestGenerator:new(props)
   local o = {props = props,
              test_csts = {},
              test_csts_values = {}}
   setmetatable(o, self)
   self.__index = self
   return o
end

function print_table(t, indent)
   if type(t) ~= "table" then
      print(string.rep(" ", indent) .. tostring(t))
   else
      for q,w in pairs(t) do
         print(string.rep(" ", indent) .. tostring(q))
         print_table(w, indent + 2)
      end
   end
end

function TestGenerator:get_test(name, rule)
   local first = self.props:first(rule)
   if first[Epsilon] then
      first[Epsilon] = nil
      for f, _ in pairs(self.props:follow(name)) do
         first[f] = true
      end
   end
   local s = {}
   for k, _ in pairs(first) do
      if k ~= EOF then
         table.insert(s, k)
      end
   end
   table.sort(s)
   key = ""
   for _, v in ipairs(s) do
      key = key .. v
   end
   local test = self.test_csts[key]
   if not test then
      local code = "test_" .. (#(self.test_csts_values)+1) .. " = { "
      for i, v in ipairs(s) do
         code = code .. string.format("[%q] = true", v)
         if i ~= #s then
            code = code .. ", "
         end
      end
      code = code .. " }\n"
      table.insert(self.test_csts_values, code)
      self.test_csts[key] = #self.test_csts_values
      test = #self.test_csts_values
   end

   local ret = "(test_" .. test .. "[la]"
   if first[EOF] then
      ret = ret .. " or la == nil)"
   else
      ret = ret .. ")"
   end
   return ret
end

function TestGenerator:write(out)
   for _, v in ipairs(self.test_csts_values) do
      out:write(v)
   end
end

function generate(rules, out)

   local props = Properties:new(rules)
   local tests = TestGenerator:new(props)

   local labels = { [1] = true }
   local nt_labels = {}

   function get_tmp_label()
      table.insert(labels, true)
      local ret = #labels
      return ret
   end
   function get_label(name)
      local ret = nt_labels[name]
      if ret then
         return ret
      end
      ret = get_tmp_label()
      nt_labels[name] = ret
      return ret
   end

   for name, rule in pairs(rules) do
      local labels = {}
      local l = get_label(name)
      out:write(string.format("function label_%d(stack, la, i, stream)\n", l))
      --out:write(string.format("print(\"parsing \"..%q)\n", name))
      if props:left_recursive(name) then
         out:write(
            string.format(
               "local rec = find_recursion(stack, label_%d, i)\n", l))
         out:write("if rec then\n")
         out:write("for k=1,#stack do\n")
         out:write("rec[#rec+1] = stack[k]\n")
         out:write("end\n")
         out:write("local scheduled = {}\n")
         out:write("for k=1,#stack do\n")
         -- FIXME: pairs is not compiled in Luajit 2, next either.
         out:write("for m, v in pairs(rec.found) do\n")
         out:write("for n=1,#v do\n"      )
         out:write("scheduled[#scheduled+1] = {stack[k][2], stack[k][1], m, v[n], stack[k][3]}")
         out:write("end\n")
         out:write("end\n")
         out:write("end\n")
         --stack[k][2](stack[k][1], get(m, stream), m, stream, v[n], stack[k][3])\n
         out:write("for y=1, #(scheduled)-1 do\n")
         out:write("scheduled[y][1](scheduled[y][2], get(scheduled[y][3], stream), scheduled[y][3], stream, scheduled[y][4], scheduled[y][5])\n")
         out:write("end\n")
         out:write("if #scheduled >= 1 then\n")
         out:write("return scheduled[#scheduled][1](scheduled[#scheduled][2], get(scheduled[#scheduled][3], stream), scheduled[#scheduled][3], stream, scheduled[#scheduled][4],  scheduled[#scheduled][5])\n")
         --out:write("return scheduled[#scheduled](stack, la, i, stream)\n")
         out:write("end\n")

         out:write("return\n")
         out:write("end\n")
         out:write(string.format("stack[1][4] = label_%d\n", l))
         out:write("stack[1][5] = i\n")
      end
      local ll = props:is_ll(name)
      --print(name, ll)
      if not ll then
         out:write("local scheduled = {}\n")
      end
      for i, r in ipairs(rule) do
         out:write(string.format("if %s then\n", tests:get_test(name, r)))
         local label = get_tmp_label()
         labels[i] = label
         if ll then
            out:write("return ")
         else
            out:write("scheduled[#scheduled+1] = ")
         end
         out:write("label_".. label)
         if ll then
            out:write("(stack, la, i, stream)\n")
         else
            out:write("\n")
         end
         if ll then
            out:write("else")
         else
            out:write("end\n")
         end
      end
      if ll then
         out:write("\nend\n")
      else
         out:write("for y=1, #(scheduled)-1 do\n")
         out:write("scheduled[y](stack, la, i, stream)\n")
         out:write("end\n")
         out:write("if #scheduled >= 1 then\n")
         out:write("return scheduled[#scheduled](stack, la, i, stream)\n")
         out:write("end\n")
      end
      out:write("end\n")
      for i=1, #rule do
         local r = rule[i]
         local l = labels[i]
         out:write("function label_" .. l .. "(stack, la, i, stream)\n")
         out:write("local nodes = { startp = i }\n")
         local nonterminals = 0
         if #r > 0 and is_terminal(r[1]) then
            out:write("i = i + 1\n")
            out:write("la = get(i, stream)\n")
         elseif #r > 0 then
            local next_label = get_tmp_label()
            out:write("local newstack = {")
            out:write(
               string.format(
                  "{ [1] = stack, [2] = label_%d, [3] = nodes }", next_label))
            out:write(", found = {} }\n");
            out:write(
               string.format("return label_%d(newstack, la, i, stream)\n",
                             get_label(r[1])))
            out:write("end\n")
            out:write(
               string.format(
                  "function label_%d(stack, la, i, stream, returned, nodes)\n",
                  next_label))
            if debug then
               out:write("assert(#nodes == " .. nonterminals .. ")\n")
            end
            nonterminals = 1
            if debug then
               out:write("assert(nodes ~= returned)\n")
            end
            out:write("nodes = shallowcopy(nodes)\n")
            out:write("nodes[#nodes+1] = returned\n")
         end
         for j=2, #r do
            if is_terminal(r[j]) then
               out:write(string.format("if la == %q then\n",
                                       get_terminal(r[j])))
               out:write("i = i + 1\n")
               out:write("la = get(i, stream)\n")
               out:write("else\n")
               out:write("return\n")
               out:write("end\n")
            else
               local next_label = get_tmp_label()
               local rest = {}
               for k=j, #r do
                  rest[k-j+1] = r[k]
               end
               out:write("local newstack = { ")
               out:write(
                  string.format("{ [1] = stack, [2] = label_%d, [3] = nodes }",
                                next_label))
               out:write(", found = {} }\n")
               out:write(
                  string.format("return label_%d(newstack, la, i, stream)\n",
                                get_label(r[j])))
               out:write("end\n")
               out:write(
                  string.format(
                     "function label_%d(stack,la,i,stream,returned,nodes)\n",
                     next_label))
               if debug then
                  out:write(
                     string.format("assert(#nodes == %d)\n", nonterminals))
               end
               nonterminals = nonterminals + 1
               if debug then
                  out:write("assert(nodes ~= returned)\n")
               end
               out:write("nodes = shallowcopy(nodes)\n")
               out:write("table.insert(nodes, returned)\n")
            end
         end
         if r.cons then
            out:write(string.format("nodes.cons = %q\n", r.cons))
         end
         out:write("nodes.endp = i\n")
         if debug then
            out:write(string.format("assert(#nodes == %d)\n", nonterminals))
         end
         out:write("success, nodes = parsed(nodes)\n")
         out:write("if not success then\n")
         out:write("return\n")
         out:write("end\n")
         if props:left_recursive(name) then
            out:write("if not stack.found[i] then\n")
            out:write("stack.found[i] = { nodes }\n")
            out:write("else\n")
            out:write("table.insert(stack.found[i], nodes)\n")
            out:write("end\n")
         end
         out:write("local len=#stack\n")
         out:write("for r=1, len-1 do\n")
         out:write("stack[r][2](stack[r][1],la,i,stream,nodes,stack[r][3])\n")
         out:write("end\n")
         out:write("return stack[len][2](" ..
                   "stack[#stack][1], la, i, stream, nodes, stack[len][3])\n")
         out:write("end\n")
      end
   end

   tests:write(out)

   local start_sym = get_label("S")

   out:write("function start(stack, stream)\n")
   out:write(string.format("label_%d(stack, get(0, stream), 0, stream)\n",
                           start_sym))
   out:write("end\n")
end
