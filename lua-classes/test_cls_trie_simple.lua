-- -*- coding: utf-8 -*-

local cls_trie = require('cls_pdnm_trie_simple')

local t = cls_trie:new()
local r = t:get_root()
t:set_value(r, 1)
print(t:get_value(r))
