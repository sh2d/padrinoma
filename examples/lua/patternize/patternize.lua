-- -*- coding: utf-8 -*-

--[[

   Copyright 2013 Stephan Hennig

   This file is part of Padrinoma.

   Padrinoma is free software: you can redistribute it and/or modify it
   under the terms of the GNU Affero General Public License as published
   by the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   Padrinoma is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public
   License along with Padrinoma.  If not, see
   <http://www.gnu.org/licenses/>.

   Diese Datei ist Teil von Padrinoma.

   Padrinoma ist Freie Software: Sie können es unter den Bedingungen der
   GNU Affero General Public License, wie von der Free Software
   Foundation, Version 3 der Lizenz oder (nach Ihrer Wahl) jeder
   späteren veröffentlichten Version, weiterverbreiten und/oder
   modifizieren.

   Padrinoma wird in der Hoffnung, dass es nützlich sein wird, aber OHNE
   JEDE GEWÄHELEISTUNG, bereitgestellt; sogar ohne die implizite
   Gewährleistung der MARKTFÄHIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN
   ZWECK.  Siehe die GNU Affero General Public License für weitere
   Details.

   Sie sollten eine Kopie der GNU Affero General Public License zusammen
   mit diesem Programm erhalten haben. Wenn nicht, siehe
   <http://www.gnu.org/licenses/>.

--]]

-- Search files in TDS tree.
if kpse then kpse.set_program_name('luatex') end
local backend = require('patternize-backend')
local alt_getopt = require('alt_getopt')

local Ulen = unicode.utf8.len
local Usub = unicode.utf8.sub


-- Output help message.
local function help()
   local progname = arg[0]
   io.write('usage: texlua ', progname, [[ [options]
Decomposes UTF-8 encoded strings from stdin into Liang patterns and calculates spots indicating, e.g., valid hyphenation points. Results are written to stdout, optionally with decomposition information. Options:
long        short  arg   description
--help      -h           show help
--patterns  -p     file  read patterns from file '<file>'
                         When the texlua interpreter is used, files
                         '<file>' and 'hyph-<file>.pat.txt' are searched using
                         the kpse library.
                         Patterns must be pure text in UTF-8 encoding.
            -T           equivalent to -p hyph-de-1901.pat.txt
            -S           equivalent to -p hyph-de-ch-1901.pat.txt
            -R           equivalent to -p hyph-de-1996.pat.txt
--verbose   -v           output decomposition information
--leading   -l     num   set minimum leading spot distance (default 2)
--trailing  -t     num   set minimum trailing spot distance (default 2)
--mins      -m     num   set minimum leading and trailing spot distances
            -0 ... -9    equivalent to -m 0 ... -m 9
--chars     -c     chars set special characters, argument is a string of up to
                         three UTF-8 characters:
                         1. spot character, default is HYPHEN-MINUS '-'
                         2. explicit spot character, default is EQUALS SIGN '='
                         3. boundary character, default is FULL STOP '.'
]]
   )
end


local function bad_arg(option, type, got)
   io.stderr:write('option -', option, ': expected ', type, ' argument, got: ', got, '\n')
   os.exit(1)
end


-- Option parsing.
--
-- Declare options.
local long_opts = {
   help = 'h',
   patterns = 'p',
   verbose = 'v',
   leading = 'l',
   trailing = 't',
   mins = 'm',
   chars = 'c',
}
-- Parse options.
local opts, optind, optarg = alt_getopt.get_ordered_opts(arg, 'hp:TSRvl:t:m:0123456789c:', long_opts)
-- Set some default values.
local verbose = false
local leading = 2
local trailing = 2
local spot_char = '-'
local expl_spot_char = '='
local boundary_char = '.'
local patternfile = nil
-- Ordered option evaluation.
for i,v in ipairs(opts) do
   local num_opt = tonumber(v)
   local num_arg = tonumber(optarg[i])
   if num_opt then leading = num_opt; trailing = num_opt
   elseif v == 'p' then patternfile = optarg[i]
   elseif v == 'R' then patternfile = 'hyph-de-1996.pat.txt'
   elseif v == 'S' then patternfile = 'hyph-de-ch-1901.pat.txt'
   elseif v == 'T' then patternfile = 'hyph-de-1901.pat.txt'
   elseif v == 'v' then verbose = true
   elseif v == 'l' then if num_arg then leading = num_arg else bad_arg(v, 'number', optarg[i]) end
   elseif v == 't' then if num_arg then trailing = num_arg else bad_arg(v, 'number', optarg[i]) end
   elseif v == 'm' then if num_arg then leading = num_arg; trailing = num_arg else bad_arg(v, 'number', optarg[i]) end
   elseif v == 'c' then
      local chars = optarg[i]
      if Ulen(chars) < 1 then bad_arg(v, 'at least one character', optarg[i]) end
      spot_char = Usub(chars, 1, 1)
      expl_spot_char = Usub(chars, 2, 2) or expl_spot_char
      boundary_char = Usub(chars, 3, 3) or boundary_char
   elseif v == 'h' then help(); os.exit(0)
   else
      io.stderr:write('Unknown option -', v, '\n')
      help()
      os.exit(1)
   end
end
-- Check if pattern file is set.
if not patternfile then
   io.write('Please specify a pattern file!\n')
   help()
   os.exit(1)
end


-- Initialize work module.
backend.init(patternfile, verbose, leading, trailing, spot_char, expl_spot_char, boundary_char)


-- Process lines in standard input.
for line in io.lines() do
   backend.process_line(line)
end
