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

kpse.set_program_name('luatex')
local unicode = require('unicode')
local cls_spot = require('cls_pdnm_spot')
local alt_getopt = require('alt_getopt')

local Tconcat = table.concat
local Tinsert = table.insert
local Ugmatch = unicode.utf8.gmatch
local Ulen = unicode.utf8.len
local Ulower = unicode.utf8.lower
local Urep = unicode.utf8.rep


-- Output help message.
local function help()
   local progname = arg[0]
   print('usage: texlua ' .. progname .. [[ [options]
Reads UTF-8 encoded strings from standard input and decomposes them into Liang patterns. Decomposition results are visualized. Options:
long        short  arg   description
--help      -h           print help
--bletter   -b     char  set boundary letter (default is a FULL STOP '.')
--leading   -l     num   set minimum leading spot distance (default 2)
--trailing  -t     num   set minimum trailing spot distance (default 2)
--mins      -m     num   set minimum leading and trailing spot distances
            -0 ... -9    equivalent to -m 0 ... -m 9
--patterns  -p     file  set pattern file to use for decomposition
                         File is searched using the kpse library.
                         Patterns must be pure text in UTF-8 encoding.
            -T           equivalent to -p hyph-de-1901.pat.txt
            -S           equivalent to -p hyph-de-ch-1901.pat.txt
            -R           equivalent to -p hyph-de-1996.pat.txt
]]
   )
end


local function bad_arg(option, type, got)
   print('option -' .. option .. ': expected ' .. type .. ' argument, got: ' .. got)
   os.exit(1)
end


-- Option parsing.
--
-- Declare options.
local long_opts = {
   help = 'h',
   bletter = 'b',
   leading = 'l',
   trailing = 't',
   mins = 'm',
   patterns = 'p',
}
-- Parse options.
local opts, optind, optarg = alt_getopt.get_ordered_opts(arg, 'b:l:t:m:0123456789p:TSRh', long_opts)
-- Set some default values.
local bletter = '.'
local leading = 2
local trailing = 2
local patternfile = nil
-- Ordered option evaluation.
for i,v in ipairs(opts) do
   local num_opt = tonumber(v)
   local num_arg = tonumber(optarg[i])
   if num_opt then leading = num_opt; trailing = num_opt
   elseif v == 'l' then if num_arg then leading = num_arg else bad_arg(v, 'number', optarg[i]) end
   elseif v == 't' then if num_arg then trailing = num_arg else bad_arg(v, 'number', optarg[i]) end
   elseif v == 'm' then if num_arg then leading = num_arg; trailing = num_arg else bad_arg(v, 'number', optarg[i]) end
   elseif v == 'b' then if Ulen(optarg[i]) == 1 then bletter = optarg[i] else bad_arg(v, 'single character', optarg[i]) end
   elseif v == 'p' then patternfile = optarg[i]
   elseif v == 'R' then patternfile = 'hyph-de-1996.pat.txt'
   elseif v == 'S' then patternfile = 'hyph-de-ch-1901.pat.txt'
   elseif v == 'T' then patternfile = 'hyph-de-1901.pat.txt'
   elseif v == 'h' then help(); os.exit(0)
   else
      print('Unknown option -' .. v)
      help()
      os.exit(1)
   end
end
-- Check if pattern file is set.
if not patternfile then
   print('Please specify a pattern file!')
   help()
   os.exit(1)
end
-- Check if pattern file can be found.
local xpatternfile = kpse.find_file(patternfile)
if not xpatternfile then
   print('Could not find pattern file ' .. patternfile)
   os.exit(1)
end

print('boundary letter: \'' .. bletter .. '\'')
print('spot mins: ' .. leading .. ' ' .. trailing)
print('pattern file: ' .. xpatternfile)


-- Create spot class.
local spot = cls_spot:new()
spot:set_boundary_letter(bletter)
spot:set_spot_mins(leading, trailing)

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
spot.trie.record_to_value = record_to_value


do
   local fin = assert(io.open(xpatternfile, 'r'))
   local count = spot:read_patterns(fin)
   fin:close()
   io.write(count, ' patterns read.\n')
end


-- Set-up string decomposition.

local function cb_pdnm_pattern__decomposition_start(self)
   self.super.cb_pdnm_pattern__decomposition_start(self)
   local boundary = self.boundary_letter
   io.write('\n ', boundary, ' ', Tconcat(self.word, ' '), ' ', boundary, '\n')
end
spot.cb_pdnm_pattern__decomposition_start = cb_pdnm_pattern__decomposition_start

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
spot.cb_pdnm_pattern__decomposition_pattern_found = cb_pdnm_pattern__decomposition_pattern_found

local function cb_pdnm_pattern__decomposition_finish(self)
   self.super.cb_pdnm_pattern__decomposition_finish(self)
   local word = self.word
   local word_levels = self.word_levels
   -- Output string with levels.
   io.write(' ', Tconcat(self:to_word_with_levels(word, word_levels)), '\n')
   -- Output string with spots.
   io.write(Tconcat(self:to_word_with_spots(word, word_levels, '-')), '\n')
end
spot.cb_pdnm_pattern__decomposition_finish = cb_pdnm_pattern__decomposition_finish

local function debug_spots(s)
   local word = spot:to_word(Ulower(s))
   spot:find_levels(word)
end

-- Process strings in standard input.
local file = io.read('*all')
for s in Ugmatch(file, '%w+') do
   debug_spots(s)
end
