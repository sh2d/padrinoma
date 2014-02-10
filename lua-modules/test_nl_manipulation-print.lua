-- -*- coding: utf-8 -*-
local unicode = require('unicode')
local cls_spot = require('cls_pdnm_spot')

local Sformat = string.format
local Tconcat = table.concat
local Tinsert = table.insert
local Uchar = unicode.utf8.char

local function print_spots(head, twords)
   for _, word in ipairs(twords) do
      local chars = {}
      for _, n in ipairs(word.nodes) do
         Tinsert(chars, Uchar(n.char))
      end
      texio.write(Sformat('[word] %s=%s\n', Tconcat(chars), Tconcat(cls_spot:to_word_with_spots(chars, word.levels, '-'))))
   end
end

return print_spots
