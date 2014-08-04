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



--- This module implements a spot class.
-- A spot class is a special pattern class, which can calculate
-- positions (spots) within a words using Liang patterns.  Spots may
-- have a minimum distance from word boundaries.<br />
--
-- Spot information of a word is represented by a table containing
-- levels (numbers).  Odd levels represent a valid spot in a word, even
-- levels represent an invalid spot.  Indices in the level table refer
-- to positions before letters in the original word.  Level table is
-- larger than the corresponding word table by one element.
--
-- As an example, given word and level tables<pre>
--
-- word =   {  'c', 'a', 'n', 'b', 'e', 'r', 'r', 'a' }<br />
--
-- levels = { 0,   0,   2,   1,   0,   4,   3,   0,   0 }
--
-- </pre>indicates valid spot positions between letters <em>n b</em> and
-- <em>r r</em>.  Note, how the word table contains only lower case
-- letter class characters.  It is in the user's responsibility that
-- words contain only letters that match patterns.  Otherwise,
-- calculated spots may be wrong.<br />
--
-- This class is derived from class `cls_pdnm_pattern`.
--
--
-- @class module
-- @name cls_pdnm_spot
-- @author Stephan Hennig
-- @copyright 2013, Stephan Hennig

-- API-Dokumentation can be generated via <pre>
--
--   luadoc -d API *.lua
--
-- </pre>



-- Load third-party modules.
local unicode = require('unicode')
local cls_pattern = require('cls_pdnm_pattern')



--
-- @trick Prevent LuaDoc from looking past here for module description.
--[[ Trick LuaDoc into entering 'module' mode without using that command.
module(...)
--]]
-- Local module table.
local M = cls_pattern:new()



-- Short-cuts.
local Mmax = math.max
local Mmin = math.min
local Tconcat = table.concat
local Tinsert = table.insert
local Tremove = table.remove
local Ugmatch = unicode.utf8.gmatch



--- Get minimum distances of spots to word boundaries.
-- Spots determined by patterns are invalid, if distance from word
-- boundaries is less than specified by the arguments.  Spots at invalid
-- positions are suppressed.
--
-- @param self  Callee reference.
-- @return Minimum spot distances.
local function get_spot_mins(self)
   return self.leading_spot_min, self.trailing_spot_min
end
M.get_spot_mins = get_spot_mins



--- Set minimum distance of spots to word boundaries.
-- Spots determined by patterns are invalid, if distance from word
-- boundaries is less than specified by the arguments.  Spots at invalid
-- positions are suppressed.
--
-- @param self  Callee reference.
-- @param leading  Minimum spot distance to leading word boundary.
-- @param trailing  Minimum spot distance to trailing word boundary.
-- @return Old minimum distances.
local function set_spot_mins(self, leading, trailing)
   local old_leading, old_trailing = self.leading_spot_min, self.trailing_spot_min
   self.leading_spot_min = leading
   self.trailing_spot_min = trailing
   return old_leading, old_trailing
end
M.set_spot_mins = set_spot_mins



--- Call-back for preparing a new word decomposition.
-- Initialize new level table.
--
-- @see <a href='../modules/cls_pdnm_pattern.html'>class cls_pdnm_pattern</a>
local function cb_pdnm_pattern__decomposition_start(self)
   self.word_levels = { [0]=0 }
end
M.cb_pdnm_pattern__decomposition_start = cb_pdnm_pattern__decomposition_start



--- Initialize next level table key.
-- The level table value needs to be initialized, because a currently
-- ending pattern could refer to the position after the current
-- letter, e.g., a pattern `un1`.
--
-- @see <a href='../modules/cls_pdnm_pattern.html'>class cls_pdnm_pattern</a>
local function cb_pdnm_pattern__decomposition_pre_iterate_active_tries(self)
   self.word_levels[self.letter_pos] = 0
end
M.cb_pdnm_pattern__decomposition_pre_iterate_active_tries = cb_pdnm_pattern__decomposition_pre_iterate_active_tries



--- Update levels in word according to new pattern.
--
-- @see <a href='../modules/cls_pdnm_pattern.html'>class cls_pdnm_pattern</a>
local function cb_pdnm_pattern__decomposition_pattern_found(self, node, start_pos)
   for level_pos,level in pairs(self.trie:get_value(node)) do
      -- Position of level in word.
      local pos = start_pos + level_pos - 1
      -- print('level_pos '..level_pos, '   level '..level, '   pos '..pos)
      local word_levels = self.word_levels
      if level > word_levels[pos] then
         word_levels[pos] = level
      end
   end
end
M.cb_pdnm_pattern__decomposition_pattern_found = cb_pdnm_pattern__decomposition_pattern_found



--- Call-back for finishing a word decomposition.
-- Remove unneeded level table indices referring to positions beyond
-- boundary letters.  Suppress invalid spots near word boundaries.
--
-- @see <a href='../modules/cls_pdnm_pattern.html'>class cls_pdnm_pattern</a>
local function cb_pdnm_pattern__decomposition_finish(self)
   local word_levels = self.word_levels
   -- Remove meaningless levels which refer to positions beyond boundary
   -- letters.
   Tremove(word_levels)
   word_levels[0] = nil
   -- Suppress spots near word boundaries.
   for pos = 1,Mmin(self.leading_spot_min, #word_levels) do
      word_levels[pos] = 0
   end
   for pos = #word_levels, Mmax(#word_levels - self.trailing_spot_min + 1, 1), -1  do
      word_levels[pos] = 0
   end
end
M.cb_pdnm_pattern__decomposition_finish = cb_pdnm_pattern__decomposition_finish



--- Determine inter-letter levels of a word.
-- Levels are found by decomposing the given word into matching
-- patterns.  Keys (numbers) in the returned table refer to inter-letter
-- positions in the decomposed word, to be precise, to the position
-- after the first of two letters.  Note, that the original word
-- argument is wrapped in boundary letters before it is decomposed.
-- Therefore, key range is 0 to word length plus two.  That is, keys in
-- the returned table refer to positions before the second of two
-- letters in the orginal word.  As an example, a key with a value of 1
-- refers to the position before the first letter in the original word.
--
-- @param self  Callee reference.
-- @param word  A word in table representation.
-- @return Array of levels.
local function find_levels(self, word)
   assert(type(word) == 'table','Word must be in table representation. Got ' .. type(word) .. ': ' .. tostring(word))
   -- Temporarily, store word in instance for later reference, e.g., in call-backs.
   self.word = word
   -- Add boundary letters to word.
   local boundary = self.boundary_letter
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
   local word_levels = self.word_levels
   -- Remove temporary data from spot instance.
   self.word_levels = nil
   self.word = nil
   return word_levels
end
M.find_levels = find_levels



--- Create table containing all letters of a word with inter-letter
-- levels.  The word is wrapped in boundary letters.
--
-- @param self  Callee reference.
-- @param levels  A level table.
-- @param word  A word in table representation.
-- @return Table of letters and levels.
local function to_word_with_levels(self, word, levels)
   assert(type(word) == 'table','Word must be in table representation. Got ' .. type(word) .. ': ' .. tostring(word))
   local h = { self.boundary_letter }
   for pos, letter in ipairs(word) do
      Tinsert(h, levels[pos])
      Tinsert(h, letter)
   end
   Tinsert(h, levels[#levels])
   Tinsert(h, self.boundary_letter)
   return h
end
M.to_word_with_levels = to_word_with_levels



--- Get spot characters.
-- Spot characters are inserted into a word at positions, where Liang
-- pattern matching results in an odd level.  Characters in a word equal
-- to the spot character are replaced by the explicit spot character in
-- the result.  Default spot and explicit spot characters are
-- HYPHEN-MINUS (U+002D) and EQUALS SIGN (U+003D).
--
-- @param self  Callee reference.
-- @return Two characters: spot character and explicit spot character.
local function get_spot_chars(self)
   return self.spot_char, self.explicit_spot_char
end
M.get_spot_chars = get_spot_chars



--- Set spot characters.
-- Spot characters are inserted into a word at positions, where Liang
-- pattern matching results in an odd level.  Characters in a word equal
-- to the spot character are replaced by the explicit spot character in
-- the result.  Default spot and explicit spot characters are
-- HYPHEN-MINUS (U+002D) and EQUALS SIGN (U+003D).
--
-- @param self  Callee reference.
-- @param spot_ch  New spot character.
-- @param expl_spot_ch  New explicit spot character.
-- @return Two characters: old spot character and old explicit spot
-- character.
local function set_spot_chars(self, spot_ch, expl_spot_ch)
   local old_spot_ch, old_expl_spot_ch = self.spot_char, self.explicit_spot_char
   self.spot_char = spot_ch
   self.explicit_spot_char = expl_spot_ch
   return old_spot_ch, old_expl_spot_ch
end
M.set_spot_chars = set_spot_chars



--- Create table containing all letters of a word and spot letters at
--- spot positions.
-- Spot characters are inserted into a word at positions, where Liang
-- pattern matching results in an odd level.  Characters in a word equal
-- to the spot character are replaced by the explicit spot character in
-- the result.  Default spot and explicit spot characters are
-- HYPHEN-MINUS (U+002D) and EQUALS SIGN (U+003D).
--
-- @param self  Callee reference.
-- @param word  A word in table representation.
-- @param levels  A level table.
-- @param explicit_spot_char  Letters equal to spot character in input
-- are transformed to this character in output.
-- @return Table of letters and spots.
local function to_word_with_spots(self, word, levels)
   assert(type(word) == 'table','Word must be in table representation. Got ' .. type(word) .. ': ' .. tostring(word))
   local h = {}
   for pos, letter in ipairs(word) do
      if levels[pos] % 2 == 1 then Tinsert(h, self.spot_char) end
      if letter == self.spot_char then
         letter = self.explicit_spot_char
      end
      Tinsert(h, letter)
   end
   if levels[#levels] % 2 == 1 then Tinsert(h, self.spot_char) end
   return h
end
M.to_word_with_spots = to_word_with_spots



--- Create value associated with a pattern.
-- Input are a string representation of Liang patterns consisting of
-- letter class characters representing letters and digit class
-- characters representing levels.  Patterns are converted into a table
-- as follows: Indices are positions, values are the levels.  Only
-- values larger than 0 are stored.  That is, the resulting table is not
-- a sequence.  Positions (indices) refer to the first of two letters
-- with a non-zero level inbetween.  That is, position 1 refers to the
-- location between letters 1 and 2; position 0 refers to the location
-- before the first letter (in the pattern).  The resulting table is
-- used for calculating spot positions after decomposing a word into
-- patterns.
--
-- @see <a href='../modules/cls_pdnm_trie_simple.html'>class cls_pdnm_trie_simple</a>
local function record_to_value(self, pattern)
   local pat_levels = {}
   local pos = 0
   for ch in Ugmatch(pattern, '.') do
      local num = tonumber(ch)
      if num then
         pat_levels[pos] = num
      else
         pos = pos + 1
      end
   end
   return pat_levels
end



--- Convert value associated with a pattern to a string for printing.
--
-- @see <a href='../modules/cls_pdnm_trie_simple.html'>class cls_pdnm_trie_simple</a>
local function value_to_string(self, pat_levels)
   local h = {}
   for level_pos,level in pairs(pat_levels) do
      Tinsert(h, level_pos .. '=' .. level)
   end
   return Tconcat(h, ';')
end



--- Initialize object.
--
-- @param self  Callee reference.
local function init(self)
   -- Call parent class initialization function on object.
   M.super.init(self)
   -- Set custom trie functions.
   self.trie.record_to_value = record_to_value
   self.trie.value_to_string = value_to_string
   -- Set some default values.
   self:set_spot_mins(2, 2)
   self:set_spot_chars('-', '=')
end
M.init = init



-- Export module table.
return M
