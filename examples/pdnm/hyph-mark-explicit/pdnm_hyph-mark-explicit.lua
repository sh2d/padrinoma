-- -*- coding: utf-8 -*-
local unicode = require('unicode')

local Ncopy = node.copy
local Ninsert_after = node.insert_after

local function insert_hyphen(head, tnode, tparent, tlevels)
   for pos, level in ipairs(tlevels) do
      if (level % 2 == 1) and not tparent[pos-1] and not tparent[pos] then
         local hyphen = Ncopy(tnode[pos-1])
         hyphen.char = 0xb7-- MIDDLE DOT
         Ninsert_after(head, tnode[pos-1], hyphen)
      end
   end
end

return insert_hyphen
