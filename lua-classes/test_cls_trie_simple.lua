-- -*- coding: utf-8 -*-

local cls_trie = require('cls_pdnm_trie_simple')

local t = cls_trie:new()
local r = t:get_root()
print('r = ', r)
t:set_value(r, 1)
print(t:get_value(r))
print(t:find({}))
print('***')

local key = t:key('abc')
print(t:insert(key, 123))
print(t:find(key))
print('***')

print(t:insert(key, 456))
print(t:find(key))
print('***')

print(t:insert({'a', 'b', 'c'}, 789))
print(t:find(t:key('abc')))
print('***')

print(t:find(t:key('abcd')))
t:insert({'a', 'b', 'c', 'd'}, 'abcd')
print(t:find(t:key('abcd')))
