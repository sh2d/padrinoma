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
-- This is a linked table implementation of a trie data structure.  The
-- implementation does not claim to be memory or performance efficient.
-- The original purpose of this trie implementation was a flexible
-- re-implementation of <a
-- href='http://tug.org/docs/liang/'>F.M. Liang's hyphenation
-- algorithm</a> in Lua.<br />
--
-- This trie requires keys to be in table representation.  Table
-- representation of a key is a sequence of <em>letters</em> (a table
-- with values starting at index 1).  The term <em>letter</em> here
-- refers to any valid Lua value, except the value `nil`.  That is, the
-- alphabet of valid letters is not restricted to characters
-- representing letters as known from scripts.  As an example, the key
-- <code>{'h', 'e', 'l', 'l', 'o'}</code> consists of five letters (each
-- one a single character) and might represent the word
-- <code>hello</code>, while the table <code>{'hello'}</code> represents
-- an entirely different word with only a single letter (a string).  Two
-- tables represent the same key, if they contain the same combination
-- of letters (the same key/value pairs).  A function is provided to
-- convert an arbitrary key into table representation.<br />
--
-- This class is derived from class `cls_pdnm_oop`.
--
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



-- Short-cuts.
local Tinsert = table.insert
local Ugmatch = unicode.utf8.gmatch



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
-- This function stores a value in a trie associated with the given
-- node.
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



--- Convert a key to table representation.
-- A table argument is returned as is.  A string argument is converted
-- into a table containing UTF-8 characters as values, starting at index
-- 1 (a sequence).  Any non-table, non-string argument is converted into
-- a table with the argument as value at index 1 (a sequence).
--
-- @param key  Key to convert into table representation.
-- @return Key in table representation.
local function key(self, key)
   local key_type = type(key)
   if key_type == 'table' then
      return key
   elseif key_type == 'string' then
      key_table = {}
      for ch in Ugmatch(key, '.') do
         Tinsert(key_table, ch)
      end
      return key_table
   else
      return { key }
   end
end
M.key = key



--- Insert a key into a trie.
-- Any existing value is replaced by the new value.
--
-- @param self  Callee reference.
-- @param key  A key in table representation.
-- @param new_value  A non-nil value associated with the key.
-- @return Old value associated with key.
local function insert(self, key, new_value)
   assert(type(key) == 'table','Key must be in table representation. Got ' .. type(key) .. ': ' .. tostring(key))
   -- Start inserting letters at root node.
   local node = self.root
   assert(type(node) == 'table', 'Trie root not found!')
   -- Iterate over key letters.
   for _,letter in ipairs(key) do
      -- Search matching edge.
      local next = node[letter]
      -- Need to insert new edge?
      if next == nil then
         next = self:new_node()
         node[letter] = next
      end
      -- Advance.
      node = next
   end
   -- Save old value.
   local old_value = self.value[node]
   -- Set new value.
   self.value[node] = new_value
   -- Return old value.
   return old_value
end
M.insert = insert



--- Search for a key in trie.
--
-- @param self  Callee reference.
-- @param key  Key to search in table representation.
-- @return Value associated with key, or `nil` if the key cannot be found.
local function find(self, key)
   assert(type(key) == 'table','Key must be in table representation. Got ' .. type(key) .. ': ' .. tostring(key))
   -- Start searching at root node.
   local node = self.root
   assert(type(node) == 'table', 'Trie root not found!')
   -- Iterate over key letters.
   for _,letter in ipairs(key) do
      -- Search matching edge.
      node = node[letter]
      if node == nil then
         return nil
      end
   end
   -- Return value associated with target node.
   return self.value[node]
end
M.find = find



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
