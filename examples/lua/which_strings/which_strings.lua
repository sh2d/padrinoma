-- -*- coding: utf-8 -*-

kpse.set_program_name('luatex')
local unicode = require('unicode')
local alt_getopt = require('alt_getopt')
local cls_pattern = require('cls_pdnm_pattern')

local Tinsert = table.insert
local Ulen = unicode.utf8.len
local Ulower = unicode.utf8.lower


-- Output help message.
local function usage()
   local progname = arg[0]
   print('usage: texlua ' .. progname .. [[
 [-h] [-b char] [-p file]
options:
 --help       -h   print help
 --bletter    -b   set boundary letter (default is a FULL STOP '.')
 --patterns   -p   set pattern file to use for decomposition
              -T   equivalent to -p hyph-de-1901.pat.txt
              -S   equivalent to -p hyph-de-ch-1901.pat.txt
              -R   equivalent to -p hyph-de-1996.pat.txt

Reads-in a list of strings and decomposes them using Liang patterns. For every pattern, all matching strings are recorded. Strings are read from standard input and must be in the UTF-8 encoding. A pattern file specified via -p must contain pure text patterns in the UTF-8 encoding. Pattern files are searched using the kpse library. Using a boundary letter different to the one used during pattern creation can lead to wrong results.]]
   )
end


local function bad_arg(option, type, got)
   print('option -' .. option .. ': expected ' .. type .. ' argument, got: ' .. got)
   os.exit(1)
end


-- Option parsing.
--
-- Declare options.
local long_opts = {
   help = 'h',
   bletter = 'b',
   patterns = 'p',
}
-- Parse options.
local opts, optind, optarg = alt_getopt.get_ordered_opts(arg, 'b:p:TSRh', long_opts)
-- Set some default values.
local bletter = '.'
local patternfile = nil
-- Ordered option evaluation.
for i,v in ipairs(opts) do
   if v == 'b' then if Ulen(optarg[i]) == 1 then bletter = optarg[i] else bad_arg(v, 'single character', optarg[i]) end
   elseif v == 'p' then patternfile = optarg[i]
   elseif v == 'R' then patternfile = 'hyph-de-1996.pat.txt'
   elseif v == 'S' then patternfile = 'hyph-de-ch-1901.pat.txt'
   elseif v == 'T' then patternfile = 'hyph-de-1901.pat.txt'
   elseif v == 'h' then usage(); os.exit(0)
   else
      print('Unknown option -' .. v)
      usage()
      os.exit(1)
   end
end
-- Check if pattern file is set.
if not patternfile then
   print('Please specify a pattern file!')
   usage()
   os.exit(1)
end
-- Check if pattern file can be found.
local xpatternfile = kpse.find_file(patternfile)
if not xpatternfile then
   print('Could not find pattern file ' .. patternfile)
   os.exit(1)
end

print('boundary letter: \'' .. bletter .. '\'')
print('pattern file: ' .. xpatternfile)


-- Create pattern instance.
local p = cls_pattern:new()
p:set_boundary_letter(bletter)

-- Provide call-back.
local function cb_pdnm_pattern__decomposition_pattern_found(self, node, start)
   local words = node.words
   if not words then
      words = {}
      node.words = words
   end
   Tinsert(words, self.word_string)
end
p.cb_pdnm_pattern__decomposition_pattern_found = cb_pdnm_pattern__decomposition_pattern_found

local function _show(self, node)
   -- Node with associated value?
   local value = self:get_value(node)
   if value then
      io.write(value)
      if not node.words then io.write(' 0')
      else
         io.write(' ', #node.words)
         if #node.words < 2 then
            for _,word in ipairs(node.words) do
               io.write(' ', word)
            end
         end
      end
      io.write('\n')
   end
   -- Traverse into child nodes.
   for letter, next in pairs(node) do
      if letter ~= 'words' then
         self:_show(next)
      end
   end
end
p.trie._show = _show


-- Load patterns.
do
   local fin = assert(io.open(xpatternfile, 'r'))
   local count = p:read_patterns(fin)
   fin:close()
   io.write(count, ' patterns read.\n')
end


local function count_matches(s)
   -- Store string in pattern object.
   s = Ulower(s)
   p.word_string = s
   local word = p:to_word(s)
   p:decompose(word)
   -- Remove string from pattern object.
   p.word_string = nil
end

-- Read and decompose strings and do all statistics.
for line in io.lines() do
   count_matches(line)
end

p.trie:show()
