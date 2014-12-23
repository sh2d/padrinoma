-- -*- coding: utf-8 -*-

-- Read Lua configuration.
local path_dirsep, path_sep, path_subst = string.match(package.config, '(.-)\n(.-)\n(.-)\n')
-- Expand module search path.
package.path = package.path
   .. path_sep .. 'lua' .. path_dirsep .. path_subst .. '.lua'
   .. path_sep .. 'skripte' .. path_dirsep .. 'lua' .. path_dirsep .. path_subst .. '.lua'

-- Load modules.
local hrecords = require('helper_records')
local hwords = require('helper_words')
local unicode = require('unicode')

-- Short-cuts.
local Ufind = unicode.utf8.find
local Ugsub = unicode.utf8.gsub

-- Open output files.
local frounds = assert(io.open('words.german.s.rounds', 'w'))
local flongs = assert(io.open('words.german.s.longs', 'w'))

-- Read from stdin.
for line in io.lines() do
   -- Split record.
   local t = hrecords.split(line)
   -- Extract traditional spelling.
   local word = t[2] or t[3] or t[5] or t[6]
   -- Does word contain letter 's'?
   if word and Ufind(word, 's') then
      -- Transform word into patgen format.
      local norm_word = hwords.normalize_word(word).norm_word
      -- Remove all hyphens from word.
      local plain_word = Ugsub(norm_word, '-', '')
      -- Does word contain a round-s?
      if Ufind(word, 's[=<>]') or Ufind(word, 's$') then
         frounds:write(plain_word, '\n')
      end
      -- Does word contain a long-s?
      if Ufind(word, 's.') and Ufind(word, 's[^=<>]') then
         flongs:write(plain_word, '\n')
      end
   end
end
