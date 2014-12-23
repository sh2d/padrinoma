-- -*- coding: utf-8 -*-

--- Manipulation that inserts long s glyphs.
-- All round s glyphs (char code 0x73, LATIN SMALL LETTER S) followed by
-- a spot are replaced by a long s glyph (char code 0x017f, LATIN SMALL
-- LETTER LONG S).
--
-- @param head  Head of a node list.
-- @param twords  A sequence of word property tables.
local function apply_manipulation(head, twords)
   -- Iterate over words.
   for _,word in ipairs(twords) do
      -- Replace all round s glyphs followed by a spot by a long s
      -- glyph.
      for i,n in ipairs(word.nodes) do
         if n.char == 0x73 and (word.levels[i+1] % 2 == 1) then
            n.char = 0x017f
         end
      end
   end
end



-- Call-back registering.
--
-- Load padrinoma module.
local padrinoma = require('pdnm_nl_manipulation')
-- Create custom pattern matching function.
local scan_node_list = padrinoma.create_node_list_scanner('german', '../../patterns/gsub-long-s-de-1901.pat.txt', 0, 0, true)

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
