-- -*- coding: utf-8 -*-

--[[

   Copyright 2013 Stephan Hennig

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



--- This module implements is a simple trie class.
-- The implementation does not claim to be memory or performance
-- efficient.  The original purpose of this trie implementation was a
-- flexible re-implementation of <a
-- href='http://tug.org/docs/liang/'>F.M. Liang's hyphenation
-- algorithm</a> in Lua.<br />
--
-- This class is derived from class `cls_pdnm_oop`.
--
-- @class module
-- @name cls_pdnm_trie_simple
-- @author Stephan Hennig
-- @copyright 2013, Stephan Hennig

-- API-Dokumentation can be generated via <pre>
--
--   luadoc -d API *.lua
--
-- </pre>



-- Load third-party modules.
local unicode = require('unicode')
local cls_oop = require('cls_pdnm_oop')



-- @trick Prevent LuaDoc from looking past here for module description.
--[[ Trick LuaDoc into entering 'module' mode without using that command.
module(...)
--]]
-- Local module table.
local M = cls_oop:new()



--- Create new trie node.
-- This function returns a newly created trie node with no associated
-- value.
--
-- @param self  Callee reference.
-- @return Trie node.
local function new_node(self)
   self.nodes = self.nodes + 1
   return {}
end
M.new_node = new_node



--- Set value associated with a trie node.
-- This function stores a value in a trie and associates it with the
-- given node.
--
-- @param self  Callee reference.
-- @param node  Trie node.
-- @param value  New value.
-- @return Old value associated with node.
-- @see get_value
local function set_value(self, node, value)
   local old_value = self.value[node]
   self.value[node] = value
   return old_value
end
M.set_value = set_value



--- Get value associated with a trie node.
-- This function retrieves a value in a trie associated with the given
-- node.
--
-- @param self  Callee reference.
-- @param node  Trie node.
-- @return Value associated with node.
-- @see set_value
local function get_value(self, node)
   return self.value[node]
end
M.get_value = get_value



--- Get reference to root node.
-- This function returns a reference to the root node of the trie
-- object.
--
-- @param self  Callee reference.
-- @return Root node.
local function get_root(self)
   return self.root
end
M.get_root = get_root



--- Initialize object.
--
-- @param self  Callee reference.
local function init(self)
   -- Call parent class initialization function on object.
   M.super.init(self)
   -- Number of nodes in trie.
   self.nodes = 0
   -- Root node.
   self.root = self:new_node()
   -- Table of values associated with nodes.
   self.value = {}
end
M.init = init



-- Export module table.
return M
