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
local nliw = require('pdnm_nl_iterate_words')
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
local Sformat = string.format
local Tinsert = table.insert
local Tremove = table.remove
local TEXgetlccode = tex.getlccode
local Uchar = unicode.utf8.char



-- Short-cuts for constants.
local DISC = node.id('disc')
local GLYPH = node.id('glyph')



-- Local references to terminal output functions.
local err, warn, info, log = luatexbase.provides_module(module)



-- Upvalues used while processing a node list representing a word.
--
-- Entry at index i is a glyph node representing the i-th letter of a
-- word.
local tnode
-- Entry at index i is a stack of parent nodes of the i-th node in table
-- `tnode`.  Parent nodes are either discretionary nodes or glyph nodes.
-- The corresponding node in table `tnode` is then part of a
-- `replacement` or `components` sub-list of that parent node.
local tparent
-- Current stack of parent nodes.  Table `tparent` contains copies of
-- this table.
local parentstack
-- Spot object used for pattern matching.
local spot
-- Leading spot min.
local leading
-- Trailing spot min.
local trailing



--- Process a node list representing a word.
-- Collects all glyph nodes corresponding to letters in the word,
-- prepares a stack of parent nodes per glyph node and does a pattern
-- matching step for all letters in the word.<br />
--
-- Letters of a word are collected from glyph nodes in the node list.
-- Discretionary nodes add to the letters of a word with the glyph nodes
-- from their `replacement` sub-list.  Glyph nodes corresponding to a
-- ligature add to the letters of a word with the glyph nodes in their
-- `components` sub-list.<br />
--
-- @param head  Node list.
-- @return Several upvalues.
local function process_list(head)
   -- Iterate over all nodes in the list.
   for n in Ntraverse(head) do
      local nid = n.id
      if nid == GLYPH then
         -- Retrieve spot mins for current word.
         if not leading then
            leading = n.left
            trailing = n.right
         end
         -- Fundamental glyph or automatic ligature?
         local components = n.components
         if not components then
            -- Fundamental glyph.
            --
            -- Add node to table.
            Tinsert(tnode, n)
            -- Advance decomposition.
            spot:decomposition_advance(Uchar(TEXgetlccode(n.char)))
            -- Add copy of current parent node stack to table.
            local stack_copy
            if #parentstack > 0 then
               stack_copy = {}
               for i,parent in ipairs(parentstack) do
                  stack_copy[i] = parent
               end
            end
            tparent[#tnode] = stack_copy
         else
            -- Automatic ligature.
            --
            -- Update parent node stack and recurse into component
            -- node list.
            Tinsert(parentstack, n)
            process_list(components)
            Tremove(parentstack)
         end
      elseif nid == DISC then
         -- Does the discretionary contain components belonging to a
         -- non-hyphenated word?
         local replace = n.replace
         if replace then
            -- Update parent node stack and recurse into replacment
            -- node list.
            Tinsert(parentstack, n)
            process_list(replace)
            Tremove(parentstack)
         end
      end
   end
end



--- Find levels in a node list corresponding to a word.
--
-- @param spot_param  A spot object used for pattern matching.
-- @param start  First node belonging to the word.
-- @param stop  Last node belonging to the word.
-- @return Three tables containing information about the word.<br />
--
-- <ol>
--
-- <li>The first table is a sequence of glyph nodes corresponding to the
-- letters of the word.  Note, there may be additional nodes between two
-- glyph nodes in the original node list.  That is, it is wrong to
-- assume <code>t[i].next == t[i+1]</code> etc.</li>
--
-- <li>The second table contains at index <code>i</code> a stack (a
-- table) of parent nodes of the node at index <code>i</code> in the
-- first table.  A node has (nested) parent(s) if it is part of a
-- `component` sub-list of a glyph node or part of a `replace` sub-list
-- of a discretionary node.</li>
--
-- <li>The third table contains levels resulting from pattern matching
-- the word (list) against the given spot object.  An index in this
-- table refers to the position before the entry with the same index in
-- the other tables.  Therefore, this table is one item longer than the
-- other two tables.  Odd values refer to valid spots found in the
-- list/word.</li>
--
-- </ol>
local function find_levels(spot_param, start, stop)
   -- Initialize upvalues.
   spot = spot_param
   tnode = {}
   tparent = {}
   parentstack = {}
   leading = nil
   trailing = nil
   -- Initialize decomposition.
   local boundary = spot.boundary_letter
   -- Prepare new word decomposition.
   spot:decomposition_start()
   -- Process leading boundary letter.
   spot:decomposition_advance(boundary)
   -- Temporarily, make stop node last node in list.
   local stop_next = stop.next
   stop.next = nil
   -- Iterate over letters of word.
   process_list(start)
   stop.next = stop_next
   -- Process trailing boundary letter.
   spot:decomposition_advance(boundary)
   -- Adjust spot mins.  Must be done before finishing decomposition.
   if leading and trailing then
      spot:set_spot_mins(leading, trailing)
   end
   -- Finish decomposition.
   spot:decomposition_finish()
   -- Retrieve levels as result of decomposition.
   local tlevels = spot.word_levels
   spot.word_levels = nil
   return tnode, tparent, tlevels
end



-- Table of manipulations.  Maps strings (ids) to a table containing
-- information about a manipulation.
local manipulations



--- Register a new pattern driven node manipulation.
-- All manipulations registered are executed in the `hyphenate`
-- call-back.
--
-- @param pattern_name  File name of a pure text UTF-8 pattern file.
-- @param module_name  File name of a module implementing a particular
-- node manipulation.  The module must return a function, which is
-- called for every word encountered in the `hyphenate` call-back.
-- Arguments are the head of a node list, which was passed to the
-- `hyphenate` call-back, and three tables representing information
-- about a word in that node list.  See function `find_levels` for a
-- description of these tables.
-- @param id  A unique identification string associated with a
-- manipulation.
-- @see deregister_manipulation
local function register_manipulation(pattern_name, module_name, id)
   local spot = cls_spot:new()
   local fin = kpse.find_file(pattern_name)
   fin = assert(io.open(fin, 'r'), 'Pattern file ' .. pattern_name .. ' not found!')
   local count = spot:read_patterns(fin)
   fin:close()
   info(count .. ' patterns read from file ' .. pattern_name)
   local f = require(module_name)
   if type(f) ~= 'function' then
      err('Bad manipulation module ' .. module_name .. ': expected return value of type function, got ' .. type(f))
   end
   if not manipulations[id] then
      manipulations[id] = {
         spot = spot,
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
      -- Iterate over words in node list.
      for start, stop in nliw.words(head) do
         local tnode, tparent, tlevels = find_levels(manipulation.spot, start, stop)
         manipulation.f(head, tnode, tparent, tlevels)
      end
   end
   return true
end



--- Module initialization.
local function __init()
   -- Initialize manipulation table.
   manipulations = {}
   -- Register hyphenate call-back.
   luatexbase.add_to_callback('hyphenate', __cb_hyphenate, 'pdnm_hyphenate')
end



__init()



return M
