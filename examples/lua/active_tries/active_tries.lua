-- -*- coding: utf-8 -*-

kpse.set_program_name('luatex')
local unicode = require('unicode')
local alt_getopt = require('alt_getopt')
local cls_pattern_log_active = require('cls_pdnm_pattern_log_active')


-- Output help message.
local function usage()
   local progname = arg[0]
   print('usage: texlua ' .. progname .. [[ [options]
Reads UTF-8 encoded strings from standard input and decomposes them into Liang patterns. Statistical data is collected about the number of active tries per letter position. Diagrams are created for all string lengths as well as the complete list. Options:
long        short  arg   description
--help      -h           print help
--bletter   -b     char  set boundary letter (default is a FULL STOP '.')
--patterns  -p     file  set pattern file to use for decomposition
                         File is searched using the kpse library.
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
local xpatternfile = kpse.find_file(patternfile)
if not xpatternfile then
   print('Could not find pattern file ' .. patternfile)
   os.exit(1)
end

print('boundary letter: \'' .. bletter .. '\'')
print('pattern file: ' .. xpatternfile)


-- Create custom pattern class.
local p = cls_pattern_log_active:new()
p:set_boundary_letter(bletter)

-- Load patterns.
do
   local fin = assert(io.open(xpatternfile, 'r'))
   local count = p:read_patterns(fin)
   fin:close()
   io.write(count, ' patterns read.\n')
end


-- Read and decompose words and do all statistics.
for line in io.lines() do
   p:log_active(line)
end
print('min, max length: ', p.count_length.min, p.count_length.max)


-- Write cumulated distribution to files.
p:write_distribution()
-- Write distribution by word length to files.
local cum_count_length = 0
for len = p.count_length.min,p.count_length.max do
   local count_length = p.count_length[len]
   cum_count_length = cum_count_length + count_length
   print('len, count: ', len, count_length)
   p:write_distribution(len)
end
print('cumulated count: ', cum_count_length)
