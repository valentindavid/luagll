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

local runtime = require("gll.runtime")
local pairs = pairs
local setfenv = setfenv
local pcall = pcall
local loadfile = loadfile
local assert = assert
local table = table
local print = print

module "gll.loader"

function load_grammar(filename,
		      environment)
   code = assert(loadfile(filename))
   local env = {
      table = table,
      assert = assert,
      pcall = pcall,
      print = print,
      pairs = pairs
   }
   for k, v in pairs(environment) do
      env[k] = v
   end
   for k, v in pairs(runtime) do
      env[k] = v
   end
   setfenv(code, env)
   code()
   return env.start
end
