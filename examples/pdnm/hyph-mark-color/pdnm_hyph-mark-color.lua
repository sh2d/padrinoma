-- -*- coding: utf-8 -*-
local unicode = require('unicode')

local Nnew = node.new
local Ninsert_after = node.insert_after
local Ninsert_before = node.insert_before

local WHATSIT = node.id('whatsit')
local PDF_COLORSTACK = node.subtype('pdf_colorstack')

local function colorize_spots(head, tnode, tparent, tlevels)
   for pos, level in ipairs(tlevels) do
      if (level % 2 == 1) and not tparent[pos-1] and not tparent[pos] then
         local push = Nnew(WHATSIT, PDF_COLORSTACK)
         local pop = Nnew(WHATSIT, PDF_COLORSTACK)
         push.stack = 0
         pop.stack = 0
         push.command = 1
         pop.command = 2
         push.data = '1 0 0 rg'
         Ninsert_before(head, tnode[pos-1], push)
         Ninsert_after(head, tnode[pos], pop)
      end
   end
end

return colorize_spots
