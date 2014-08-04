-- -*- coding: utf-8 -*-

local unicode = require('unicode')
local cls_spot = require('cls_pdnm_spot')
local Tconcat = table.concat
local Tinsert = table.insert
local Ulower = unicode.utf8.lower


local p = cls_spot:new()
do
   local fin = assert(io.open(arg[1], 'r'))
   p:read_patterns(fin)
   fin:close()
end
p:set_spot_mins(2,2)

local function debug_spots(s)
   local word = p:to_word(Ulower(s))
   local levels = p:find_levels(word)
   print(Tconcat(p:to_word_with_levels(word, levels)))
   print(Tconcat(p:to_word_with_spots(word, levels)))
end

debug_spots('Zuckerbäcker')
debug_spots('Zucker-Bäcker')
debug_spots('Häscher')
debug_spots('Häschen')
debug_spots('Häuschen')
debug_spots('Prine')
debug_spots('Prinz')
debug_spots('Knoten')
debug_spots('Wende')
debug_spots('Energie')
debug_spots('Lausanne')
debug_spots('menschlicher')

local strings = {}
for line in io.lines() do
   Tinsert(strings, line)
end

local t1, t2 = os.time()
for _,s in ipairs(strings) do
   local h = p:find_levels(p:to_word(Ulower(s)))
end
local t2 = os.time()
print(t1, t2, t2-t1, #strings/(t2-t1))
