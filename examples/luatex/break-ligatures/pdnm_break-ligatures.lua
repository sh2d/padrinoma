-- -*- coding: utf-8 -*-
local unicode = require('unicode')
local cls_spot = require('cls_pdnm_spot')
local spot = cls_spot:new()

local Ncopy = node.copy
local Ninsert_after = node.insert_after
local Nnew = node.new
local Ntraverse = node.traverse
local Uchar = unicode.utf8.char

local GLYPH = node.id('glyph')

local ZWNJ_templ = Nnew(GLYPH)
ZWNJ_templ.char = 0x200c-- Unicode slot of ZWNJ



--- Insert a ZWNJ glyph node between two glyph nodes.
-- Position parameter points to the glyph node after a spot.  The ZWNJ
-- is inserted after the preceeding glyph node.  Which is not the same
-- as inserting before the glyph node pointed to as there may be, e.g.,
-- a discretionary between two glyph nodes.
--
-- @param head  Head of a node list.
-- @param word  A word property table.
-- @param pos  Index of glyph node after spot in word property table.
-- @return Debug information: a number.
local function process_hyphenation(head, word, pos)
   if word.parents[pos-1] or word.parents[pos] then
      -- Only plain top-level glyph nodes are handled, currently.
      return 1
   end
   local first = word.nodes[pos-1]
   local zwnj = Ncopy(ZWNJ_templ)
   zwnj.font = first.font
   zwnj.lang = first.lang
   Ninsert_after(head, first, zwnj)
   return 0
end



--- Manipulation that inserts a ZWNJ char node to prevent selected
--- ligatures.
-- This manipulation inserts a ZWNJ char node between glyph nodes at
-- every word of affix joint.  The manipulation has to be applied before
-- TeX's ligaturing stage.
--
-- @param head  Head of a node list.
-- @param twords  A sequence of word property tables.
local function apply_manipulation(head, twords)
   -- Iterate over words.
   for _, word in ipairs(twords) do
      -- Debug output.
      local w = {}
      for _, n in ipairs(word.nodes) do
         table.insert(w, Uchar(n.char))
      end
      local s = table.concat(spot:to_word_with_spots(w, word.levels))
      -- Check all valid spots.
      for pos, level in ipairs(word.levels) do
         -- Valid spot?
         if (level % 2) == 1 then
            -- Apply manipulation to glyph nodes at indices pos-1 and pos.
            local result = process_hyphenation(head, word, pos)
            texio.write_nl('[word joint] ' .. s .. ' ' .. tonumber(pos-1) .. ':' .. tostring(result))
         end
      end
   end
end



-- Call-back registering.
--
-- Load padrinoma module.
local padrinoma = require('pdnm_nl_manipulation')
-- Create custom pattern matching function.
local scan_node_list = padrinoma.create_node_list_scanner('german', '../../patterns/hyph-de-1901-joint.pat.txt', 2, 2, true)

local nlp = require('pdnm_nl_printer')
local printer = nlp.new_simple_printer('[node] ')

-- Register hyphenate call-back.
luatexbase.add_to_callback('ligaturing',
                           function (head, tail)
                              printer(head)
                              -- Do pattern matching.
                              local twords = scan_node_list(head)
                              -- Apply node list manipulation.
                              apply_manipulation(head, twords)
                              -- Apply regular ligaturing.
                              node.ligaturing(head)
                           end,
                           'pdnm_ligaturing')
