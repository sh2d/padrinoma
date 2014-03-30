-- -*- coding: utf-8 -*-
local unicode = require('unicode')
local cls_spot = require('cls_pdnm_spot')

local spot = cls_spot:new()
local pattern_name = 'hyph-de-1901.pat.txt'
local fin = kpse.find_file(pattern_name)
fin = assert(io.open(fin, 'r'), 'Could not open pattern file ' .. pattern_name .. '!')
local count = spot:read_patterns(fin)
fin:close()
print(count .. ' patterns read from file ' .. pattern_name)

local Ncopy = node.copy
local Nfree = node.free
local Ninsert_after = node.insert_after
local Ninsert_before = node.insert_before
local Nnew = node.new
local Nremove = node.remove
local Tconcat = table.concat
local Tinsert = table.insert
local TEXgetlccode = tex.getlccode
local Uchar = unicode.utf8.char

local DISC = node.id('disc')
local GLYPH = node.id('glyph')

--- Apply a discretionary replacement.
-- Triple consonant rule as well as ck rule are handled uniformly: Two
-- nodes <code>12</code> are replaced by a
-- <code>\discretionary{.}{}{1}2</code>, where . is a rule specific
-- replacement.  A less invasive replacement exists for the case of
-- triple consonant rule, but uniform handling of both rules allows for
-- better code sharing.
--
-- @param head  Head of a node list.
-- @param twords  A sequence of word property tables.
local function hyphenate_with_explicit_hyphen(head, twords)
   for _, word in ipairs(twords) do
      local chars = {}
      for _,n in ipairs(word.nodes) do
         Tinsert(chars, Uchar(n.char))
      end
      texio.write(Tconcat(spot:to_word_with_spots(chars, word.levels, '-', '=')))
      -- Only process words containing explicit hyphens.
      if word.exhyphenchars then
         -- Insert trailing fake explicit hyphen.
         Tinsert(word.exhyphenchars, #word.nodes+1)
         local last_exhyphen_pos = 0
         for i_exhyphen,curr_exhyphen_pos in ipairs(word.exhyphenchars) do
            spot:decomposition_start()
            spot:decomposition_advance(spot.boundary)
            for i = last_exhyphen_pos+1,curr_exhyphen_pos-1 do
               spot:decomposition_advance(Uchar(TEXgetlccode(word.nodes[i].char)))
            end
            spot:decomposition_advance(spot.boundary)
            local leading_spot_min = 8
            local trailing_spot_min = 8
            -- Take hyphen minima from original word for outer word boundaries.
--            if i_exhyphen == 1 then
--               leading_spot_min = word.nodes[curr_exhyphen_pos-1].left
--            end
--            if i_exhyphen == #word.exhyphenchars then
--               trailing_spot_min = word.nodes[curr_exhyphen_pos-1].right
--            end
            spot:set_spot_mins(leading_spot_min, trailing_spot_min)
            spot:decomposition_finish()
            for pos,level in ipairs(spot.word_levels) do
               word.levels[last_exhyphen_pos+1+pos-1] = spot.word_levels[pos]
            end
            last_exhyphen_pos = curr_exhyphen_pos
         end
         local chars = {}
         for _,n in ipairs(word.nodes) do
            Tinsert(chars, Uchar(n.char))
         end
         texio.write(' : ')
         texio.write(Tconcat(spot:to_word_with_spots(chars, word.levels, '-', '=')))
         for pos, level in ipairs(word.levels) do
            -- Spot with surrounding top-level glyph nodes?
            if (level % 2 == 1) and not word.parents[pos-1] and not word.parents[pos] then
               local first = word.nodes[pos-1]
               local second = word.nodes[pos]
               -- Create discretionary node.
               local d = Nnew(DISC, 0)
               d.attr = first.attr
               -- Sub-list .pre:
               --
               -- Make copy of first node, changing char to hyphen.
               local glyph_hyph = Ncopy(first)
               glyph_hyph.char = 0x2d
               d.pre = glyph_hyph
--               local prefirst = first.prev
--               local presecond = second.prev
               -- Sub-list .replace:
               --
               -- Unlink list (first)--(second.prev).
--               prefirst.next = second
--               second.prev = prefirst
               -- And put it into .replace field.
--               first.prev = nil
--               presecond.next = nil
--               d.replace = first
               -- Insert discretionary before second node.
               Ninsert_before(head, second, d)
            end
         end
      end
      texio.write('\n')
   end
end

return hyphenate_with_explicit_hyphen
