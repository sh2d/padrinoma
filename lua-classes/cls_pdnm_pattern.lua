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



--- This module implements a pattern class.
-- A pattern object can decompose words into matching patterns.<br />
--
-- Some terminology: A word consists of letters of an alphabet in a
-- particular order (a word is a variation of letters with repetition).
-- In this context, the alphabet is not limited to, e.g., the set of
-- letter class characters in a particular character encoding, but can
-- be any value that can be represented in Lua, except the value
-- `nil`.<br />
--
-- A word is represented by a table, containing <a
-- href='http://www.lua.org/manual/5.2/manual.html'>a sequence</a> of
-- its letters.  Functions with a word parameter accept only words in
-- table representation.  A function is provided for converting
-- arbitrary values into table representation.  A table containing no
-- sequence, i.e., no value at index 1, represents an empty word, which
-- is a perfectly valid word.  Words are equal with respect to pattern
-- decomposition, if they consist of the same variation of letters.<br
-- />
--
-- As an example, the table <code>{'h', 'e', 'l', 'l', 'o'}</code>,
-- represents a word consisting of five letters, while the tables
-- <code>{'he', 'll', 'o'}</code> and <code>{'hello'}</code> represent
-- two entirely different words, the former consisting of three letters,
-- the latter consisting of a single letter only.<br />
--
-- Note, this class decomposes words without ever touching letter case.
-- The user has to make sure that words to decompose fit the patterns
-- used.<br />
--
-- Two interfaces are provided for word decomposition, a word-based one
-- and a letter-based one.  The word-based one takes a complete word as
-- argument and decomposes it into matching patterns.  The letter-based
-- one can be used when the word to decompose is not readily available
-- as a whole, but letters are input one after another.  Whatever
-- interface is used, the process of decomposition into patterns can be
-- customized using several call-backs.<br />
--
-- This class is derived from class `cls_pdnm_oop`.
--
--
-- @class module
-- @name cls_pdnm_pattern
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
local cls_trie = require('cls_pdnm_trie_simple')



-- @trick Prevent LuaDoc from looking past here for module description.
--[[ Trick LuaDoc into entering 'module' mode without using that command.
module(...)
--]]
-- Local module table.
local M = cls_oop:new()



-- Short-cuts.
local Tinsert = table.insert
local Tremove = table.remove
local Ugmatch = unicode.utf8.gmatch



--- Get letter, words are padded with before applying pattern
-- operations.  Default boundary letter is a FULL STOP (U+002E).
--
-- @param self  Callee reference.
-- @return Boundary letter.
local function get_boundary_letter(self, boundary)
   return self.boundary_letter
end
M.get_boundary_letter = get_boundary_letter



--- Set letter, words are padded with before applying pattern
-- operations.  This letter must correspond to the character used while
-- creating the patterns.  Default boundary letter is a FULL STOP
-- (U+002E).
--
-- @param self  Callee reference.
-- @param boundary  New boundary letter.
-- @return Old boundary letter.
local function set_boundary_letter(self, boundary)
   local old_boundary = self.boundary_letter
   self.boundary_letter = boundary
   return old_boundary
end
M.set_boundary_letter = set_boundary_letter



--- Read patterns from a file.
-- This function reads patterns from a file and stores them in a trie.
-- Patterns have to be in the UTF-8 encoding and be separated by white
-- space.  The given file handle is not closed.
--
-- @param self  Callee reference.
-- @param fin  File handle to read patterns from.
-- @return Number of patterns read.
local function read_patterns(self, fin)
   return self.trie:read_file(fin, '%S+')
end
M.read_patterns = read_patterns



--- Convert a word to table representation.
-- Table arguments are returned unchanged.  String arguments must be in
-- the UTF-8 encoding and is converted into a table containing
-- characters as values, starting at index 1 (a sequence).  Non-table,
-- non-string arguments are converted into a table with their value as a
-- single letter at index 1 (a sequence).
--
-- @param word  Word to convert into table representation.
-- @return Word in table representation.
local function to_word(self, word)
   local word_type = type(word)
   if word_type == 'table' then
      return word
   elseif word_type == 'string' then
      word_table = {}
      for ch in Ugmatch(word, '.') do
         Tinsert(word_table, ch)
      end
      return word_table
   else
      return { word }
   end
end
M.to_word = to_word



--- Call-back: Called during word decomposition, after preparing a new
-- word decomposition.  This call-back can be used for custom variable
-- initialization.
--
-- @param self  Callee reference.
-- @see decomposition_start
local function cb_pdnm_pattern__decomposition_start(self)
end
M.cb_pdnm_pattern__decomposition_start = cb_pdnm_pattern__decomposition_start



--- Prepare a new word decomposition.
-- Needs to be called for initializing a new word decomposition.
--
-- @param self  Callee reference.
-- @see cb_pdnm_pattern__decomposition_start
local function decomposition_start(self)
   -- Initialize current letter position and stack of active tries.
   self.letter_pos = 0
   self.active = {}
   self:cb_pdnm_pattern__decomposition_start()
end
M.decomposition_start = decomposition_start



--- Call-back: Called during word decomposition, before the set of
-- active tries is iterated (for the current letter).
--
-- @param self  Callee reference.
-- @see decomposition_advance
local function cb_pdnm_pattern__decomposition_pre_iterate_active_tries(self)
end
M.cb_pdnm_pattern__decomposition_pre_iterate_active_tries = cb_pdnm_pattern__decomposition_pre_iterate_active_tries



--- Call-back: Called during word decomposition, whenever a matching
-- pattern is identified.  Do nothing, by default.
--
-- @param self  Callee reference.
-- @param node  Trie node, which triggered the match.
-- @param start  Letter position in word where match begins.
-- @see decomposition_advance
local function cb_pdnm_pattern__decomposition_pattern_found(self, node, start)
end
M.cb_pdnm_pattern__decomposition_pattern_found = cb_pdnm_pattern__decomposition_pattern_found



--- Advance current word decomposition by one letter.
--
-- @param self  Callee reference.
-- @param letter  A word letter.
-- @see cb_pdnm_pattern__decomposition_pattern_found
-- @see cb_pdnm_pattern__decomposition_pre_iterate_active_tries
local function decomposition_advance(self, letter)
   -- Retrieve current decomposition status.
   local letter_pos = self.letter_pos + 1
   local active = self.active
   -- Update letter position.
   self.letter_pos = letter_pos
   -- Insert new active trie state into stack.
   Tinsert(active, {node=self.trie_root, start_pos=letter_pos})
   -- Iterate (backwards) over all active trie states.
   self:cb_pdnm_pattern__decomposition_pre_iterate_active_tries()
   for i = #active,1,-1 do
      -- Retrieve a trie state of interest.
      local state = active[i]
      -- Advance current trie.
      local target = state.node[letter]
      -- Valid step?
      if target then
         -- Update state.
         state.node = target
         -- Check current trie node for associated value.
         if self.trie:get_value(target) ~= nil then
            -- Call-back.
            self:cb_pdnm_pattern__decomposition_pattern_found(target, state.start_pos)
         end
      else
         Tremove(active, i)
      end
   end
end
M.decomposition_advance = decomposition_advance



--- Call-back: Called during word decomposition, before cleaning-up the
-- current word decomposition.  This call-back can be used for
-- interpreting the results of a word decomposition and cleaning-up
-- custom variables.
--
-- @param self  Callee reference.
-- @see decomposition_finish
local function cb_pdnm_pattern__decomposition_finish(self)
end
M.cb_pdnm_pattern__decomposition_finish = cb_pdnm_pattern__decomposition_finish



--- Finish the current word decomposition.
-- Needs to be called for cleaning-up a finished word decomposition.
--
-- @param self  Callee reference.
-- @see cb_pdnm_pattern__decomposition_finish
local function decomposition_finish(self)
   self:cb_pdnm_pattern__decomposition_finish()
   -- Remove data from pattern object.
   self.letter_pos = nil
   self.active = nil
end
M.decomposition_finish = decomposition_finish



--- Decompose a word into matching patterns.
-- This function decomposes a word into all matching patterns.  Several
-- call-backs are provided that can be used for customizing the process
-- of decomposition, e.g., whenever a matching pattern is identified.
--
-- @param self  Callee reference.
-- @param word  A word to decompose in table representation.
-- @see cb_pdnm_pattern__decomposition_start
-- @see cb_pdnm_pattern__decomposition_pattern_found
-- @see cb_pdnm_pattern__decomposition_finish
local function decompose(self, word)
   assert(type(word) == 'table','Word must be in table representation. Got ' .. type(word) .. ': ' .. tostring(word))
   -- Temporarily, store word argument in pattern object for further reference.
   self.word = word
   -- Local reference to boundary letter.
   local boundary = self:get_boundary_letter()
   -- Prepare new word decomposition.
   self:decomposition_start()
   -- Process leading boundary letter.
   self:decomposition_advance(boundary)
   -- Iterate over letters of word.
   for _,letter in ipairs(word) do
      self:decomposition_advance(letter)
   end
   -- Process trailing boundary letter.
   self:decomposition_advance(boundary)
   -- Clean-up decomposition.
   self:decomposition_finish()
   -- Remove temporarily stored data from pattern object.
   self.word = nil
end
M.decompose = decompose



--- Convert a pattern read from a file into a key to insert into pattern
-- trie.  By default, key letters are the non-digit class UTF-8
-- characters of the pattern string, i.e., all characters not
-- representing levels (in table representation).
--
-- @param self  Callee reference.
-- @param pattern  A pattern string.
-- @return Key.
-- @see file_records
local function record_to_key(self, pattern)
   local key = {}
   for ch in Ugmatch(pattern, '%D') do
      Tinsert(key, ch)
   end
   return key
end



--- Convert a pattern read from a file into a value to be associated with
-- a key in pattern trie.  By default, the unmodified pattern string is
-- returned.
--
-- @param self  Callee reference.
-- @param pattern  A pattern string.
-- @return Value.
-- @see file_records
local function record_to_value(self, pattern)
   return pattern
end



--- Initialize object.
--
-- @param self  Callee reference.
local function init(self)
   -- Call parent class initialization function on object.
   M.super.init(self)
   -- Create a trie object for storing patterns.
   local trie = cls_trie:new()
   trie.record_to_key = record_to_key
   trie.record_to_value = record_to_value
   self.trie = trie
   -- Store trie root in pattern object for later reference.
   self.trie_root = trie:get_root()
   -- Set some default values.
   self:set_boundary_letter('\x2E')-- Unicode FULL STOP, '.'
end
M.init = init



-- Export module table.
return M
