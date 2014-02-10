-- -*- coding: utf-8 -*-
local unicode = require('unicode')
local cls_spot = require('cls_pdnm_spot')

local Sformat = string.format
local Tconcat = table.concat
local Tinsert = table.insert
local Uchar = unicode.utf8.char

local function print_spots(head, tnode, tparent, tlevels)
   local tword = {}
   for _, n in ipairs(tnode) do
      Tinsert(tword, Uchar(n.char))
   end
   texio.write(Sformat('[word] %s=%s\n', Tconcat(tword), Tconcat(cls_spot:to_word_with_spots(tword, tlevels, '-'))))
end

return print_spots
