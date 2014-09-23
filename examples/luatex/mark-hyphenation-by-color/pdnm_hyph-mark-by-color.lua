-- -*- coding: utf-8 -*-
local unicode = require('unicode')

local Nnew = node.new
local Ninsert_after = node.insert_after
local Ninsert_before = node.insert_before

local WHATSIT = node.id('whatsit')
local PDF_COLORSTACK = node.subtype('pdf_colorstack')

local function colorize_spots(head, twords)
   for _, word in ipairs(twords) do
      -- Only process words not containing explicit hyphens.
      if not word.exhyphenchars then
         for pos, level in ipairs(word.levels) do
            if (level % 2 == 1) and not word.parents[pos-1] and not word.parents[pos] then
               local push = Nnew(WHATSIT, PDF_COLORSTACK)
               local pop = Nnew(WHATSIT, PDF_COLORSTACK)
               push.stack = 0
               pop.stack = 0
               push.command = 1
               pop.command = 2
               push.data = '1 0 0 rg'
               Ninsert_before(head, word.nodes[pos-1], push)
               Ninsert_after(head, word.nodes[pos], pop)
            end
         end
      end
   end
end



-- Call-back registering.
--
-- Load padrinoma module.
local padrinoma = require('pdnm_nl_manipulation')
-- Create custom pattern matching function.
local scan_node_list = padrinoma.create_node_list_scanner('latin', 'hyph-la.pat.txt', -1, -1, true)

-- Register hyphenate call-back.
luatexbase.add_to_callback('hyphenate',
                           function (head, tail)
                              -- Apply regular hyphenation.
                              lang.hyphenate(head)
                              -- Do pattern matching.
                              local twords = scan_node_list(head)
                              -- Apply node list manipulation.
                              return colorize_spots(head, twords)
                           end,
                           'pdnm_hyphenate')
