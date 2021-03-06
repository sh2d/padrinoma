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
local Tsort = table.sort
local Ugmatch = unicode.utf8.gmatch
local Ulen = unicode.utf8.len
local Ulower = unicode.utf8.lower
local Urep = unicode.utf8.rep


local M = {}


-- Set-up string decomposition for non-verbose output.

local function decomposition_finish__non_verbose(self)
   self.super.cb_pdnm_pattern__decomposition_finish(self)
   local word = self.word
   local word_levels = self.word_levels
   -- Output string with spots.
   io.write(Tconcat(self:to_word_with_spots(word, word_levels)), '\n')
end


-- Provide pattern reader for verbose output.

local function record_to_value__verbose(self, pattern)
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


-- Set-up string decomposition for verbose output.

local function decomposition_start__verbose(self)
   self.super.cb_pdnm_pattern__decomposition_start(self)
   local boundary = self.boundary_letter
   io.write('\n ', boundary, ' ', Tconcat(self.word, ' '), ' ', boundary, '\n')
   -- Store matching patterns separated by start position.
   self.matching_patterns = {}
end


local function decomposition_pattern_found__verbose(self, node, start_pos)
   for level_pos,level in pairs(self.trie:get_value(node).levels) do
      -- Position of level in word.
      local pos = start_pos + level_pos - 1
      -- io.stderr:write('level_pos ', level_pos, '   level ', level, '   pos ', pos, '\n')
      local word_levels = self.word_levels
      if level > word_levels[pos] then
         word_levels[pos] = level
      end
   end
   -- Store pattern and start position.
   if not self.matching_patterns[start_pos] then self.matching_patterns[start_pos] = {} end
   Tinsert(self.matching_patterns[start_pos], self.trie:get_value(node).xpattern)
end


local function decomposition_finish__verbose(self)
   self.super.cb_pdnm_pattern__decomposition_finish(self)
   -- Output matching patterns one pattern per line.  To keep a diagonal
   -- form (as much as possible), patterns matching at smaller start
   -- positions are output first.  Within multiple patterns starting at
   -- the same letter position, shorter patterns are output first.
   --
   -- Sort matching pattern start positions.
   local sorted_start_positions = {}
   for start_pos in pairs(self.matching_patterns) do
      Tinsert(sorted_start_positions, start_pos)
   end
   Tsort(sorted_start_positions)
   -- Iterate over matching pattern start positions.
   for _,start_pos in ipairs(sorted_start_positions) do
      -- Sort patterns matching at the same start position by pattern
      -- length.
      Tsort(self.matching_patterns[start_pos], function(s1, s2) return Ulen(s1) < Ulen(s2) end)
      -- Output sorted patterns.
      for _,xpattern in ipairs(self.matching_patterns[start_pos]) do
         io.write(Urep(' ', 2*(start_pos-1)), xpattern, '\n')
      end
   end
   -- Destroy decomposition information.
   self.matching_patterns = nil
   -- Show results.
   local word = self.word
   local word_levels = self.word_levels
   -- Output string with levels.
   io.write(' ', Tconcat(self:to_word_with_levels(word, word_levels)), '\n')
   -- Output string with spots.
   io.write(Tconcat(self:to_word_with_spots(word, word_levels)), '\n')
end


-- Create module local spot instance.
local spot = cls_spot:new()


local function init(patternfile, verbose, leading, trailing, spot_char, expl_spot_char, boundary_char)
   -- Set-up object methods.
   if verbose then
      spot.trie.record_to_value = record_to_value__verbose
      spot.cb_pdnm_pattern__decomposition_start = decomposition_start__verbose
      spot.cb_pdnm_pattern__decomposition_pattern_found = decomposition_pattern_found__verbose
      spot.cb_pdnm_pattern__decomposition_finish = decomposition_finish__verbose
   else
      spot.cb_pdnm_pattern__decomposition_finish = decomposition_finish__non_verbose
   end
   -- Check if pattern file can be found.
   if not patternfile then
      io.stderr:write('Invaild pattern file name', '\n')
      os.exit(1)
   end
   -- Try opening pattern file.
   local fin = io.open(patternfile, 'r')
   if not fin then
      local kpsepatternfile
      -- Search with kpse?
      if kpse then
         kpsepatternfile = kpse.find_file(patternfile) or kpse.find_file('hyph-' .. patternfile .. '.pat.txt')
      end
      if not kpsepatternfile then
         io.stderr:write('Could not find pattern file ', patternfile, '\n')
         os.exit(1)
      end
      patternfile = kpsepatternfile
      fin = assert(io.open(patternfile, 'r'))
   end
   -- Read patterns from file (must be done after setting-up spot.trie.*
   -- variables).
   local count = spot:read_patterns(fin)
   fin:close()
   io.write('pattern file: ', patternfile, ' (', count, ' patterns read)\n')
   -- Print parameters.
   io.write('spot mins, special characters: ', leading, ' ', trailing, ' \'', spot_char, expl_spot_char, boundary_char, '\'\n')
   -- Set spot instance parameters.
   spot:set_spot_mins(leading, trailing)
   spot:set_spot_chars(spot_char, expl_spot_char)
   spot:set_boundary_letter(boundary_char)
end
M.init = init


-- Process a line given as string.
local function process_line(line)
   -- Process all words in line.
   for s in Ugmatch(line, '%S+') do
      local word = spot:to_word(Ulower(s))
      spot:find_levels(word)
   end
end
M.process_line = process_line


return M
