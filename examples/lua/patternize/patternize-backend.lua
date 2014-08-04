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

local unicode = require('unicode')
local cls_spot = require('cls_pdnm_spot')

local Tconcat = table.concat
local Tinsert = table.insert
local Ugmatch = unicode.utf8.gmatch
local Ulower = unicode.utf8.lower
local Urep = unicode.utf8.rep


local M = {}


-- Read patterns.
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
   local xpattern = {}
   local is_number_last = false
   for ch in Ugmatch(pattern, '.') do
      local num = tonumber(ch)
      if num then
         Tinsert(xpattern, num)
         is_number_last = true
      else
         if not is_number_last then Tinsert(xpattern, ' ') end
         Tinsert(xpattern, ch)
         is_number_last = false
      end
   end
   return {levels=pat_levels, xpattern=Tconcat(xpattern) }
end


-- Set-up string decomposition.

local function cb_pdnm_pattern__decomposition_start(self)
   self.super.cb_pdnm_pattern__decomposition_start(self)
   local boundary = self.boundary_letter
   io.write('\n ', boundary, ' ', Tconcat(self.word, ' '), ' ', boundary, '\n')
end


local function cb_pdnm_pattern__decomposition_pattern_found(self, node, start_pos)
   for level_pos,level in pairs(self.trie:get_value(node).levels) do
      -- Position of level in word.
      local pos = start_pos + level_pos - 1
      -- print('level_pos '..level_pos, '   level '..level, '   pos '..pos)
      local word_levels = self.word_levels
      if level > word_levels[pos] then
         word_levels[pos] = level
      end
   end
   io.write(Urep(' ', 2*(start_pos-1)), self.trie:get_value(node).xpattern, '\n')
end


local function cb_pdnm_pattern__decomposition_finish(self)
   self.super.cb_pdnm_pattern__decomposition_finish(self)
   local word = self.word
   local word_levels = self.word_levels
   -- Output string with levels.
   io.write(' ', Tconcat(self:to_word_with_levels(word, word_levels)), '\n')
   -- Output string with spots.
   io.write(Tconcat(self:to_word_with_spots(word, word_levels)), '\n')
end


-- Create module local spot instance and overwrite some of its functions.
local spot = cls_spot:new()
spot.trie.record_to_value = record_to_value
spot.cb_pdnm_pattern__decomposition_finish = cb_pdnm_pattern__decomposition_finish
spot.cb_pdnm_pattern__decomposition_start = cb_pdnm_pattern__decomposition_start
spot.cb_pdnm_pattern__decomposition_pattern_found = cb_pdnm_pattern__decomposition_pattern_found


local function init(patternfile, bletter, leading, trailing)
   -- Check if pattern file can be found.
   local kpsepatternfile = kpse.find_file(patternfile)
   if not kpsepatternfile then
      print('Could not find pattern file ' .. patternfile)
      os.exit(1)
   end
   -- Print parameters.
   print('boundary letter: \'' .. bletter .. '\'')
   print('spot mins: ' .. leading .. ' ' .. trailing)
   print('pattern file: ' .. kpsepatternfile)
   -- Set spot instance  parameters.
   spot:set_boundary_letter(bletter)
   spot:set_spot_mins(leading, trailing)
   -- Read patterns from file.
   do
      local fin = assert(io.open(kpsepatternfile, 'r'))
      local count = spot:read_patterns(fin)
      fin:close()
      io.write(count, ' patterns read.\n')
   end
end
M.init = init


-- Process a line given as string.
local function process_line(line)
   -- Process all words in line.
   for s in Ugmatch(line, '%w+') do
      local word = spot:to_word(Ulower(s))
      spot:find_levels(word)
   end
end
M.process_line = process_line


return M
