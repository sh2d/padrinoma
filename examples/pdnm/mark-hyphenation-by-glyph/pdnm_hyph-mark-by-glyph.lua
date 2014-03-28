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

return insert_hyphen
