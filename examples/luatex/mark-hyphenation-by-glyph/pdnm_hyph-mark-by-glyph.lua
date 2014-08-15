-- -*- coding: utf-8 -*-
local unicode = require('unicode')

local Ncopy = node.copy
local Ninsert_after = node.insert_after

local function insert_hyphen(head, twords)
   for _, word in ipairs(twords) do
      -- Only process words not containing explicit hyphens.
      if not word.exhyphenchars then
         for pos, level in ipairs(word.levels) do
            if (level % 2 == 1) and not word.parents[pos-1] and not word.parents[pos] then
               local hyphen = Ncopy(word.nodes[pos-1])
               hyphen.char = 0xb7-- MIDDLE DOT
               Ninsert_after(head, word.nodes[pos-1], hyphen)
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
local scan_node_list = padrinoma.create_node_list_scanner('hyph-la.pat.txt', 'latin', true)

-- Register hyphenate call-back.
luatexbase.add_to_callback('hyphenate',
                           function (head, tail)
                              -- Apply regular hyphenation.
                              lang.hyphenate(head)
                              -- Do pattern matching.
                              local twords = scan_node_list(head)
                              -- Apply node list manipulation.
                              return insert_hyphen(head, twords)
                           end,
                           'pdnm_hyphenate')
