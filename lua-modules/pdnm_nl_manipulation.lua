-- -*- coding: utf-8 -*-

--[[

   Copyright 2014 Stephan Hennig

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



--- Pattern driven node list manipulation.
-- Provide means for pattern driven node list manipulation.
--
--
-- @class module
-- @name pdnm_node_list_manipulation
-- @author Stephan Hennig
-- @copyright 2014, Stephan Hennig

-- API-Dokumentation can be generated via <pre>
--
--   luadoc -d API *.lua
--
-- </pre>



-- Table for module identification (see below).
local module = {
   name        = 'pdnm_nl_manipulation',
   date        = '2014/01/22',
   version     = '0.1',
   description = 'pattern driven node list manipulation',
   author      = 'Stephan Hennig',
   licence     = 'GNU AGPL ver. 3',
}



-- Load third-party modules.
local unicode = require('unicode')
local cls_spot = require('cls_pdnm_spot')



--
-- @trick Prevent LuaDoc from looking past here for module description.
--[[ Trick LuaDoc into entering 'module' mode without using that command.
module(...)
--]]
-- Local module table.
local M = {}



-- Short-cuts.
local Ntraverse = node.traverse
local Tconcat = table.concat
local Tinsert = table.insert
local Tremove = table.remove
local Tsort = table.sort
local TEXgetlccode = tex.getlccode
local Uchar = unicode.utf8.char
local Ugsub = unicode.utf8.gsub



-- Short-cuts for constants.
local DISC = node.id('disc')
local GLYPH = node.id('glyph')
local WHATSIT = node.id('whatsit')
local USER_DEFINED = node.subtype('user_defined')



-- Local references to terminal output functions.
local err, warn, info, log = luatexbase.provides_module(module)



--- Word property table.
-- @name word property table
-- @class table
-- @field nodes
-- A sequence of glyph nodes corresponding to the letters of the word.
-- Note, there may be additional nodes between two glyph nodes in the
-- original node list.  That is, the assumption <code>nodes[i].next ==
-- nodes[i+1]</code> doesn't hold generally.<br />
--
-- Discretionary nodes add to the letters of a word with the glyph nodes
-- from their `replacement` sub-list.  Glyph nodes corresponding to a
-- ligature add to the letters of a word with the glyph nodes in their
-- `components` sub-list.  This has some implications:<br />
--
-- <ul>
--
--   <li>While automatic ligatures are replaced by (the nodes of) their
--   constituting characters, there can be glyph nodes representing
--   standard ligatures if they are already present in the input
--   stream.</li>
--
-- </ul>
--
-- @field exhyphenchars
-- A sequence; values indicate character positions that equal the value
-- of <code>\exhyphenchar</code>.  TeX normally doesn't insert
-- discretionaries in words containing explicit hyphens.  Looking at
-- this field, one can imitate that behaviour.  If a word contains no
-- explicit hyphens, this field is set to the value `nil` instead of an
-- empty table.
--
-- @field parents
-- A table; the element at index i refers to the node at index i in
-- table `nodes` and is either `nil` or a stack (a table) containing
-- references to parent nodes.  Parent nodes are either discretionary
-- nodes or glyph nodes, the latter corresponding to an automatic
-- ligature (the glyph node is part of a node list from a `components`
-- field).  An application of this table is refraining from applying
-- manipulations to nodes that are not top-level glyph nodes, i.e., when
-- the value in this table is non-`nil`.  If a word contains only
-- top-level glyph nodes, this field is set to the value `nil` instead
-- of an empty table.
--
-- @field levels
-- A sequence of levels resulting from matching the given spot object
-- against the letters of the word.  The level at index i in this table
-- refers to the position between nodes at indices i-1 and i in the
-- other tables (at word boundaries, only one of those two nodes
-- actually exists).  Since a word with n letters has n+1 legal level
-- positions, this table is one item longer than the other two tables.
-- Odd values refer to valid spots found in the word.



-- Module-wide variables.
--
-- Table of manipulations.  Maps strings (ids) to a table containing
-- information about a manipulation.
local manipulations
-- A table mapping manipulation id's to closures.  At the end of the
-- LuaTeX run these closures are called and write debugging information
-- to a file.
local debug_information



--- Create a custom function that processes a node list.
-- Argument of the returned function is a node list.  The node list is
-- scanned for words in the given language.  All words found are matched
-- against the given patterns.  Return value is a sequence of word
-- property tables.
--
-- @param pattern_name  Name of a pure text UTF-8 pattern file.
-- @param language_num  A language number patterns are associated with.
-- @param id  A unique identification string associated with a
-- manipulation.
-- @param is_debug  If this flag is <code>true</code>, at the end of the
-- TeX run, a list of words with spots according to the given patterns
-- is written to a file for debugging purposes.  By default, debugging
-- is inactive.
-- @return Custom node list scanner funtion.
-- @see match_patterns
local function create_node_list_scanner(pattern_name, language_num, id, is_debug)

   -- Upvalues used while matching patterns against the words in a node
   -- list.
   --
   -- Spot object used for pattern matching.
   local spot
   -- Table of words with spots as strings (for debugging).
   local words_with_spots = {}
   --
   -- A sequence of word property tables of the words found in the node
   -- list.
   local words
   -- This table corresponds to field `nodes` in a word property table.
   local word_nodes
   -- This table corresponds to field `exhyphenchars` in a word property
   -- table.
   local word_exhyphenchars
   -- This table corresponds to field `parents` in a word property
   -- table.
   local word_parents
   -- Current stack of parent nodes.  Table `word_parents` contains
   -- copies of this table.
   local parentstack
   -- Flag.
   local is_within_word


   --- Initialize a new current word.
   -- Prepare a new word decomposition.
   local function new_current_word()
      -- Flag current word mode.
      is_within_word = true
      -- Initialize some upvalues.
      word_nodes = {}
      word_exhyphenchars = nil
      word_parents = {}
      parentstack = {}
      -- Prepare new word decomposition.
      spot:decomposition_start()
      -- Process leading boundary letter.
      spot:decomposition_advance(spot.boundary_letter)
   end


   --- Finish the current word.
   -- Finish word decomposition.  Calculate spot positions for the word
   -- and store word properties in a property table.
   local function finish_current_word()
      -- Reset current word flag.
      is_within_word = false
      -- Ignore empty words, because we cannot access their nodes.
      if #word_nodes == 0 then
         return
      end
      -- Last node of word.
      local last_glyph = word_nodes[#word_nodes]
      -- Is this a word of the current pattern language?
      if last_glyph.lang ~= language_num then
         return
      end
      -- Adjust spot mins.  Must be done before finishing decomposition.
      spot:set_spot_mins(last_glyph.left, last_glyph.right)
      -- Process trailing boundary letter.
      spot:decomposition_advance(spot.boundary_letter)
      -- Finish decomposition.
      spot:decomposition_finish()
      -- Insert processed word into word table.
      Tinsert(words, {
                 nodes = word_nodes,
                 exhyphenchars = word_exhyphenchars,
                 parents = word_parents,
                 levels = spot.word_levels,
                     }
      )
      -- Debug spots?
      if is_debug then
         local chars = {}
         for _, n in ipairs(word_nodes) do
            Tinsert(chars, Uchar(n.char))
         end
         words_with_spots[Tconcat(spot:to_word_with_spots(chars, spot.word_levels))] = true
      end
   end


   --- Scan a node list for words.
   -- Collects all words subject to pattern matching in the node list.
   -- Match a spot object against the letters (glyph nodes) of the words
   -- and store results in property tables.<br />
   --
   -- The current implementation doesn't fully comply with TeX's notion
   -- of 'words subject to hyphenation'.  As an example, words next to
   -- an <code>\hbox</code> aren't hyphenated by TeX and changes in the
   -- language imply word boundaries.  Here's a link to <a
   -- href="https://foundry.supelec.fr/scm/viewvc.php/trunk/source/texk/web2c/luatexdir/lang/texlang.w?root=luatex&view=markup">the
   -- relevant LuaTeX C source code</a>.  See <a
   -- href="http://tug.org/pipermail/tex-hyphen/2014-January/001071.html">this
   -- mail</a> on the tex-hyphen list.
   --
   -- @param head  Node list.
   -- @return Upvalues.
   local function do_scan_node_list(head)
      for n in Ntraverse(head) do
         local nid = n.id
         if nid == GLYPH then
            local lc = TEXgetlccode(n.char)
            if lc > 0 then
               -- Initialize a new word?
               if not is_within_word then
                  new_current_word()
               end
               -- Fundamental glyph or automatic ligature?
               local components = n.components
               if not components then
                  -- Fundamental glyph.
                  --
                  -- Add node to table.
                  Tinsert(word_nodes, n)
                  if n.char == tex.exhyphenchar then
                     word_exhyphenchars = word_exhyphenchars or {}
                     Tinsert(word_exhyphenchars, #word_nodes)
                  end
                  -- Advance decomposition.
                  spot:decomposition_advance(Uchar(lc))
                  -- Add copy of current parent node stack to table.
                  local stack_copy
                  if #parentstack > 0 then
                     stack_copy = {}
                     for i,parent in ipairs(parentstack) do
                        stack_copy[i] = parent
                     end
                  end
                  word_parents[#word_nodes] = stack_copy
               else
                  -- Automatic ligature.
                  --
                  -- Update parent node stack and recurse into component
                  -- node list.
                  Tinsert(parentstack, n)
                  do_scan_node_list(components)
                  Tremove(parentstack)
               end
            elseif is_within_word then
               finish_current_word()
            end
         elseif nid == DISC then
            if not is_within_word then
               new_current_word()
            end
            -- Does the discretionary contain components belonging to a
            -- non-hyphenated word?
            local replace = n.replace
            if replace then
               -- Update parent node stack and recurse into replacment
               -- node list.
               Tinsert(parentstack, n)
               do_scan_node_list(replace)
               Tremove(parentstack)
            end
         elseif (nid == WHATSIT and nsubtype == USER_DEFINED)
         then
            -- Ignore node.  Don't change state.
         else
            -- Non-word node.
            if is_within_word then
               finish_current_word()
            end
         end
      end
   end


   --- Set-up a new node list scan.
   --
   -- @param head  A node list.
   -- @return A sequence of word property tables.
   -- @see do_scan_node_list
   local function scan_node_list(head)
      -- Initialize upvalues.
      words = {}
      is_within_word = false
      -- Process list.
      do_scan_node_list(head)
      -- Post-process last word.
      if is_within_word then
         finish_current_word()
      end
      -- Remove unneeded references in upvalues.
      spot.word_levels = nil
      word_nodes = nil
      word_exhyphenchars = nil
      word_parents = nil
      parent_stack = nil
      local twords = words
      words = nil
      return twords
   end


   --- Write debugging information associated to the node list scanner.
   -- If the debug flag is <code>true</code>, write debugging
   -- information at the end of the LuaTeX run to a file.  Debugging
   -- information consists of a list of all words handled by the node
   -- list scanner with hyphens inserted at spot positions.  File name
   -- is the pattern file name augmented by the extension
   -- <code>.spots</code>.
   local function write_debug_information()
      if is_debug then
         -- Sort words.
         local a = {}
         for k,_ in pairs(words_with_spots) do
            Tinsert(a, k)
         end
         Tsort(a)
         -- Remove all path information from pattern file name.
         local plain_pattern_name = Ugsub(pattern_name, '^.*/', '')
         -- Write words to file.
         local fout = assert(io.open(plain_pattern_name .. '.spots', 'w'))
         for _,v in ipairs(a) do
            fout:write(v, '\n')
         end
         fout:close()
      end
   end


   -- Initialize custom spot object.
   spot = cls_spot:new()
   do
      local fin = kpse.find_file(pattern_name)
      fin = assert(io.open(fin, 'r'), 'Pattern file ' .. pattern_name .. ' not found!')
      local count = spot:read_patterns(fin)
      fin:close()
      info(count .. ' patterns read from file ' .. pattern_name)
   end
   -- Store custom function writing debug information to a file.
   debug_information[id] = write_debug_information
   -- Return custom pattern matching function.
   return scan_node_list
end
M.create_node_list_scanner = create_node_list_scanner



--- Register a new pattern driven node manipulation.
-- All manipulations registered are executed in the `hyphenate`
-- call-back.
--
-- @param language_num  A language number patterns are associated with.
-- @param pattern_name  File name of a pure text UTF-8 pattern file.
-- @param module_name  File name of a module implementing a particular
-- node manipulation.  The module must return a function, which is
-- called for every node list encountered in the `hyphenate` call-back.
-- Arguments are the head of a node list, which was passed to the
-- `hyphenate` call-back, and a table containing a sequence of word
-- property tables.
-- @param id  A unique identification string associated with a
-- manipulation.
-- @param is_debug  Flag determining if a list of words with spots
-- should be written to a file at the end of the TeX run for debugging
-- purposes.  By default, debugging is inactive.
-- @see deregister_manipulation
local function register_manipulation(language_num, pattern_name, module_name, id, is_debug)
   local f = require(module_name)
   if type(f) ~= 'function' then
      err('Bad manipulation module ' .. module_name .. ': expected return value of type function, got ' .. type(f))
   end
   if not manipulations[id] then
      manipulations[id] = {
         scan_node_list = create_node_list_scanner(pattern_name, language_num, id, is_debug),
         f = f,
      }
   end
end
M.register_manipulation = register_manipulation



--- De-register a pattern driven node manipulation.
-- Manipulations are  identified by the ID given during registration.
--
-- @param id  A unique identification string associated with the
-- manipulation to remove.
-- @return `true`, if the module was registered, else `false`.
-- @see register_manipulation
local function deregister_manipulation(id)
   local is_active = manipulations[id]
   if is_active then
      manipulations[id] = nil
      debug_information[id] = nil
   end
   return is_active and true or false
end
M.deregister_manipulation = deregister_manipulation



--- (internal) This function is registered in hyphenate call-back.
--
-- @param head  Node list.
-- @return The value `true`.
local function __cb_hyphenate(head)
   -- Apply regular hyphenation.
   lang.hyphenate(head)
   -- Apply additional pattern driven node manipulation.
   for _, manipulation in pairs(manipulations) do
      -- Process words in node list.
      local words = manipulation.scan_node_list(head)
      -- Apply user-defined manipulation.
      manipulation.f(head, words)
   end
   return true
end



--- (internal) Write debugging information.
-- Write all words handled by a manipulation to a file.  File name is
-- the pattern file name augmented by the extension <code>.spots</code>.
local function __cb_write_debug_information()
   for _, write_debug_information in pairs(debug_information) do
      write_debug_information()
   end
end



--- Module initialization.
local function __init()
   -- Initialize manipulation table.
   manipulations = {}
   -- Initialize debugging information table.
   debug_information = {}
   -- Register hyphenate call-back.
   luatexbase.add_to_callback('hyphenate', __cb_hyphenate, 'pdnm_hyphenate')
   -- Register stop run call-back for spot debugging output.
   luatexbase.add_to_callback('stop_run', __cb_write_debug_information, 'pdnm_write_debug_information')
end



__init()



return M
