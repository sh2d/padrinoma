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
-- <em>Some numbers:</em> Storing 435,000 German words with 5.4 million
-- characters results in a trie with 1.2 million nodes consuming 77 MB
-- of memory.  That is, in this example application, a single node in
-- the trie uses ca. 69 bytes of memory.  Other than that, the
-- implementation is fully functional.  <em>But you have been
-- warned!</em><br />
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
local Tconcat = table.concat
local Tinsert = table.insert
local Tremove = table.remove
local Ufind = unicode.utf8.find
local UAsub = unicode.ascii.sub
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



--- Get buffer size used for reading files.
--
-- @param self  Callee reference.
-- @return Buffer size in bytes.
-- @see read_file
local function get_buffer_size(self)
   return self.file_buffer_size
end
M.get_buffer_size = get_buffer_size



--- Set buffer size used for reading files.
--
-- @param self  Callee reference.
-- @param buffer_size  New buffer size in bytes.
-- @return Old buffer size in bytes.
-- @see read_file
local function set_buffer_size(self, buffer_size)
   local old_buffer_size = self.file_buffer_size
   self.file_buffer_size = buffer_size
   return old_buffer_size
end
M.set_buffer_size = set_buffer_size



--- Get chunk iterator.
-- Reading records from files is done through a buffer.  This function
-- returns an iterator over the chunks.  You might want to refer to this
-- iterator when implementing a custom record iterator.  The file handle
-- argument is not closed.
--
-- @param self  Callee reference.
-- @param fin  Input file handle.
-- @return Chunk iterator.
-- @see read_file
-- @see file_records
-- @see set_buffer_size
-- @see get_buffer_size
local function file_chunks(self, fin)
   -- Check for valid file handle.
   assert(fin, 'Invalid input file handle.')
   -- Get local reference to buffer size.
   local BUFFERSIZE = self:get_buffer_size()

   return function ()
      -- Read next chunk.
      local chunk, rest = fin:read(BUFFERSIZE, '*l')
      -- EOF?
      if not chunk then
         return
      end
      if rest then chunk = chunk .. rest .. '\n' end
      return chunk
   end
end
M.file_chunks = file_chunks



--- Get record iterator.
-- This function returns an iterator over the records in a file.
-- Records are specified by the last argument, which must be a Lua
-- string pattern.  The file handle argument is not closed.
--
-- @param self  Callee reference.
-- @param fin  Input file handle.
-- @param rec_pattern  A Lua string pattern, determining what is
-- considered a record.
-- @return Record iterator.
-- @see read_file
-- @see file_chunks
-- @see set_buffer_size
local function file_records(self, fin, rec_pattern)
   -- Chunk iterator.
   local next_chunk = self:file_chunks(fin)
   -- Initialize chunk.
   local chunk = next_chunk() or ''
   local pos = 1

   return function()
      repeat
         local s, e = Ufind(chunk, rec_pattern, pos)
         -- Record found?
         if s then
            -- Update position.
            pos = e + 1
            -- Return record.
            return UAsub(chunk, s, e)
         else
            -- Read new chunk.
            chunk = next_chunk()
            -- EOF?
            if not chunk then
               return
            end
            pos = 1
         end
      until false
   end
end
M.file_records = file_records



--- Convert a record read from a file into a key to insert into trie.
-- By default, table representation of the record is returned.
--
-- @param self  Callee reference.
-- @param record  A record.
-- @return Key.
-- @see read_file
local function record_to_key(self, record)
   return self:key(record)
end
M.record_to_key = record_to_key



--- Convert a record read from a file into a value to be associated with
--- a key in trie.
-- By default, the value `true` is returned.
--
-- @param self  Callee reference.
-- @param record  A record.
-- @return Value.
-- @see read_file
local function record_to_value(self, record)
   return true
end
M.record_to_value = record_to_value



--- Read a file and store the contents in trie.
-- This function callback driven reads a file and stores the contents in
-- the trie.  The given file handle is not closed.
--
-- Note, files are buffered while reading.  Lines in the input file are
-- always read as a whole into the buffer.  The record pattern is always
-- searched for in the current read buffer.  That is, records cannot be
-- larger than the file buffer.  In general, this is not a restriction.
-- If it is for you, you have to replace this function with a custom
-- one.
--
-- @param self  Callee reference.
-- @param fin  File handle to read records from.
-- @param rec_pattern  A Lua string pattern, determining what is
-- considered a record.  If this parameter is an empty string or `nil`,
-- records are considered complete lines (without line ending
-- characters).
-- @return Number new (keys, value) pairs stored in trie.
-- @see record_to_key
-- @see record_to_value
-- @see file_records
-- @see file_chunks
-- @see set_buffer_size
local function read_file(self, fin, rec_pattern)
   -- Initialize record pattern.
   if rec_pattern == nil or rec_pattern == '' then
      rec_pattern = '[^\n\r]+'
   end
   local count = 0
   for record in self:file_records(fin, rec_pattern) do
      local key = self:record_to_key(record)
      local value = self:record_to_value(record)
      local old_value = self:insert(key, value)
      if value ~= old_value and value ~= nil then
         count = count + 1
      end
   end
   return count
end
M.read_file = read_file



--- Converts a value associated with a key in the trie into string.
--  By default, Lua's `tostring` function is applied to the value.
--
-- @param self  Callee reference.
-- @param value  A value.
-- @return String represenation of the value.
-- @see _show
local function value_to_string(self, value)
   return tostring(value)
end
M.value_to_string = value_to_string



-- Declare two upvalues used in function _show:
--
-- Print keys in compact format?
local flag_compact
-- A table containing the letters of the key leading to the current
-- node.
local letters



--- (internal) This function recursively advances through the trie.
-- It prints all letters valid at a node.  If a key is found, the
-- associated value is printed, separated by an equals sign `=` from the
-- key.
--
-- @param self  Callee reference.
-- @param node  A trie node.
-- @see show
-- @usage Internal function.
local function _show(self, node)
   -- Has current node an associated value?
   local value = self.value[node]
   if value ~= nil then
      io.write(Tconcat(letters), '=', self:value_to_string(value), '\n')
      -- Print letters leading to this node only once.
      if flag_compact then
         -- Replace latest letter in key by a space.
         for i,_ in ipairs(letters) do
            letters[i] = ' '
         end
      end
   end
   -- Recurse into child nodes.
   for letter, next in pairs(node) do
      Tinsert(letters, letter)
      _show(self, next)
      Tremove(letters)
      -- Print letters leading to this node only once.
      if flag_compact then
         for i,_ in ipairs(letters) do
            letters[i] = ' '
         end
      end
   end
end
M._show = _show



--- Print all keys stored in a trie.
-- Values are separated by an hash mark.
--
-- @param self  Callee reference.
-- @param compact  boolean flag: Print keys in compact format?
-- @see _show
local function show(self, compact)
   assert(type(self.root) == 'table', 'Trie root not found!')
   -- Initialize upvalues.
   flag_compact = compact
   letters = {}
   -- Recurse, starting at root node.
   self:_show(self.root)
end
M.show = show



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
   -- Set default buffer size used for file reading.
   self:set_buffer_size(8*1024*1024)
end
M.init = init



-- Export module table.
return M
