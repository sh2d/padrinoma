-- -*- coding: utf-8 -*-

local unicode = require('unicode')
local pattern = require('cls_pdnm_pattern')

local Ulower = unicode.utf8.lower


local p = pattern:new()
collectgarbage('collect')
local a,b,c = collectgarbage('count')

do
   local count = p:read_patterns(io.stdin)
   io.write(count, ' patterns read\n')
end

b = collectgarbage('count')
collectgarbage('collect')
c = collectgarbage('count')
print(a, b, c, (c-a)/1024 .. ' MB')
print('nodes: ', p.trie.nodes, 'per node: ', (c-a)*1024/p.trie.nodes .. ' bytes')

-- Provide call-back.
local function cb_pdnm_pattern__decomposition_pattern_found(self, node, start)
   print(self.letter_pos, start, self.trie:get_value(node))
end
p.cb_pdnm_pattern__decomposition_pattern_found = cb_pdnm_pattern__decomposition_pattern_found

local function decompose(s)
   local word = p:to_word(Ulower(s))
   return p:decompose(word)
end

decompose('Anfang')
decompose('Tagung')
decompose('Ende')
