-- -*- coding: utf-8 -*-

--[[

   Copyright 2014 Stephan Hennig

   This file is part of Padrinoma.

   Padrinoma is free software: you can redistribute it and/or modify it
   under the terms of the GNU Affero General Public License as published
   by the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   Padrinoma is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public
   License along with Padrinoma.  If not, see
   <http://www.gnu.org/licenses/>.

   Diese Datei ist Teil von Padrinoma.

   Padrinoma ist Freie Software: Sie können es unter den Bedingungen der
   GNU Affero General Public License, wie von der Free Software
   Foundation, Version 3 der Lizenz oder (nach Ihrer Wahl) jeder
   späteren veröffentlichten Version, weiterverbreiten und/oder
   modifizieren.

   Padrinoma wird in der Hoffnung, dass es nützlich sein wird, aber OHNE
   JEDE GEWÄHELEISTUNG, bereitgestellt; sogar ohne die implizite
   Gewährleistung der MARKTFÄHIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN
   ZWECK.  Siehe die GNU Affero General Public License für weitere
   Details.

   Sie sollten eine Kopie der GNU Affero General Public License zusammen
   mit diesem Programm erhalten haben. Wenn nicht, siehe
   <http://www.gnu.org/licenses/>.

--]]



--- A tiny node list printer module.
-- Provides means to print a node list to the log file.
--
--
-- @class module
-- @name pdnm_node_list_printer
-- @author Stephan Hennig
-- @copyright 2014, Stephan Hennig

-- API-Dokumentation can be generated via <pre>
--
--   luadoc -d API *.lua
--
-- </pre>



-- Table for module identification (see below).
local module = {
   name        = 'pdnm_nl_printer',
   date        = '2014/01/07',
   version     = '0.1',
   description = 'tiny node list printer',
   author      = 'Stephan Hennig',
   licence     = 'GNU AGPL ver. 3',
}



-- Load third-party modules.
local unicode = require('unicode')



--
-- @trick Prevent LuaDoc from looking past here for module description.
--[[ Trick LuaDoc into entering 'module' mode without using that command.
module(...)
--]]
-- Local module table.
local M = {}



local Ntraverse = node.traverse
local Ntype = node.type
local Sformat = string.format
local Srep = string.rep
local Uchar = unicode.utf8.char

local DISC = node.id('disc')
local GLYPH = node.id('glyph')
local HLIST = node.id('hlist')
local VLIST = node.id('vlist')


-- Local references to terminal output functions.
local err, warn, info, log = luatexbase.provides_module(module)



--- (Factory) Get a new node list printer function.
--
-- @param grep  A string, which is printet at the beginning of every
-- line.  Can be used to have something one can grep for in log files.
-- @return A function, which takes as argument a node list head and
-- writes a string representation to the log file.
local function new_printer(grep)


   -- Table of functions printing detailed node information.
   local print_node_details


   -- Iterate over the nodes of a node list and print node information.
   local function print_node_list(head, indent)
      local grep_indent = grep .. Srep(' ', indent)
      -- Traverse node list.
      for n in Ntraverse(head) do
         -- Print general node information.
         texio.write_nl(Sformat('%s%-12s subtype: %3s n: %1s p: %1s\n', grep_indent, Ntype(n.id), n.subtype, n.next and 't' or 'n', n.prev and 't' or 'n'))
         -- Print detailed node information.
         if print_node_details[n.id] then print_node_details[n.id](n, indent) end
      end
   end


   --- Table of functions, which can print details of a particular
   --- node type.  Key is the node type (a number).  Value is a function.
   --- Arguments of the functions are a node and a number determining the
   --- number of spaces (indentation) to output before printing node
   --- details.
   --
   -- @class table
   -- @name print_node_details
   print_node_details = {

      [DISC] = function(n, indent)
         local grep_indent = grep .. Srep(' ', indent)
         texio.write_nl(Sformat('%s+pre\n', grep_indent))
         print_node_list(n.pre, indent+2)
         texio.write_nl(Sformat('%s+post\n', grep_indent))
         print_node_list(n.post, indent+2)
         texio.write_nl(Sformat('%s+replace\n', grep_indent))
         print_node_list(n.replace, indent+2)
      end,

      [GLYPH] = function(n, indent)
         local grep_indent = grep .. Srep(' ', indent)
         texio.write_nl(Sformat('%s+char: %s %#-8X comp: %1s lang: %3d font: %3d\n', grep_indent, Uchar(n.char), n.char, n.components and 't' or 'n', n.lang, n.font))
         texio.write_nl(Sformat('%s+left: %3d right: %3d uchyph: %3d\n', grep_indent, n.left, n.right, n.uchyph))
         -- Ligature components?
         if n.components then print_node_list(n.components, indent+2) end
      end,

      [HLIST] = function(n, indent)
         local grep_indent = grep .. Srep(' ', indent)
         texio.write_nl(Sformat('%s+dir: %s w: %d h: %d d: %d s: %d\n', grep_indent, n.dir, n.width, n.height, n.depth, n.shift))
         print_node_list(n.head, indent+2)
      end,

      [VLIST] = function(n, indent)
         local grep_indent = grep .. Srep(' ', indent)
         texio.write_nl(Sformat('%s+dir: %s w: %d h: %d d: %d s: %d\n', grep_indent, n.dir, n.width, n.height, n.depth, n.shift))
         print_node_list(n.head, indent+2)
      end,

   }


   return function(head)
      print_node_list(head, 0)
      texio.write_nl(Sformat('%s%s\n', grep, '***'))
   end
end
M.new_printer = new_printer



return M
