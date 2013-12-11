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
print('***')

print(t:insert(t:key('abcde'), 1))
print(t:insert(t:key('abcx'), 2))
print('***')

function t:value_to_string(value)
   return '\''..tostring(value)..'\''
end

t:show()
t:show(true)



local t2 = cls_trie:new()
collectgarbage('collect')
local a,b,c = collectgarbage('count')

do
   local count = t2:read_file(io.stdin)
   io.write(count, ' records read\n')
end

b = collectgarbage('count')
collectgarbage('collect')
c = collectgarbage('count')
print(a, b, c, (c-a)/1024 .. ' MB')
print('nodes: ', t2.nodes, 'per node: ', (c-a)*1024/t2.nodes .. ' bytes')
