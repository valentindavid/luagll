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

module "gll.runtime"

function find_recursion(stack, label, i)
   while stack do
      if stack[1][4] == label and stack[1][5] == i then
	 return stack
      end
      stack = stack[1][1]
   end
end

function shallowcopy(node)
   local copy = { cons = node.cons,
		  startp = node.startp,
		  endp = node.endp }
   for i=1, #node do
      copy[i] = node[i]
   end
   return copy
end
