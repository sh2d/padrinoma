-- -*- coding: utf-8 -*-

-- Search files in TDS tree.
if kpse then kpse.set_program_name('luatex') end
local unicode = require('unicode')
local alt_getopt = require('alt_getopt')
local cls_pattern = require('cls_pdnm_pattern')

local Tinsert = table.insert
local Ulen = unicode.utf8.len
local Ulower = unicode.utf8.lower


-- Output help message.
local function usage()
   local progname = arg[0]
   print('usage: texlua ' .. progname .. [[ [options]
Reads UTF-8 encoded strings from standard input and decomposes them into Liang patterns. For every pattern, all matching strings are recorded. Options:
long        short  arg   description
--help      -h           print help
--bletter   -b     char  set boundary letter (default is a FULL STOP '.')
--patterns  -p     file  read patterns from file '<file>'
                         When the texlua interpreter is used, files
                         '<file>' and 'hyph-<file>.pat.txt' are searched using
                         the kpse library.
                         Patterns must be pure text in UTF-8 encoding.
            -T           equivalent to -p hyph-de-1901.pat.txt
            -S           equivalent to -p hyph-de-ch-1901.pat.txt
            -R           equivalent to -p hyph-de-1996.pat.txt
]]
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
local fin = io.open(patternfile, 'r')
if fin then
   -- File exists.
   fin:close()
else
   local kpsepatternfile
      -- Search with kpse?
   if kpse then
      kpsepatternfile = kpse.find_file(patternfile) or kpse.find_file('hyph-' .. patternfile .. '.pat.txt')
   end
   if not kpsepatternfile then
      print('Could not find pattern file ' .. patternfile)
      os.exit(1)
   end
   patternfile = kpsepatternfile
end


print('boundary letter: \'' .. bletter .. '\'')
print('pattern file: ' .. patternfile)


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
   local fin = assert(io.open(patternfile, 'r'))
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
