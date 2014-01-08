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



--- Provide means to iterate over the words in a node list.
--
--
-- @class module
-- @name pdnm_node_list_iterate_words
-- @author Stephan Hennig
-- @copyright 2014, Stephan Hennig

-- API-Dokumentation can be generated via <pre>
--
--   luadoc -d API *.lua
--
-- </pre>



-- Table for module identification (see below).
local module = {
   name        = 'pdnm_nl_iterate_words',
   date        = '2014/01/08',
   version     = '0.1',
   description = 'provide means to iterate over the words in a node list',
   author      = 'Stephan Hennig',
   licence     = 'GNU AGPL ver. 3',
}



-- Load third-party modules.
local unicode = require('unicode')



--
-- @trick Prevent LuaDoc from looking past here for module description.
--[[ Trick LuaDoc into entering 'module' mode without using that command.
module(...)
--]]
-- Local module table.
local M = {}



-- Short-cuts.



-- Short-cuts for constants.
local DISC = node.id('disc')
local GLYPH = node.id('glyph')
local WHATSIT = node.id('whatsit')
local USER_DEFINED = node.subtype('user_defined')



-- Local references to terminal output functions.
local err, warn, info, log = luatexbase.provides_module(module)



--- (Factory) Get a new word iterator.
-- The iterator function returned iterates over a node list and fires a
-- callback for every word found.
--
-- @param cb_process_word  Callback function to fire for every word
-- found.  Argument to the callback function are two tables containing
-- information about the word found.<br />
--
-- In node list representation, a word is a series of consecutive nodes
-- of type `glyph`, `disc`, `kern` or `penalty`, starting with a glyph
-- node.<br />
--
-- Table represenation consists of two tables, that are the arguments to
-- the callback function.  Keys in both tables are character positions
-- (1..n).<br />
--
-- <ol>
--
-- <li>The first table contains as values the nodes of type `glyph`
-- corresponding to the characrers of the word.  Discretionary nodes
-- within a node list add to this table with the glyph nodes found in
-- their `replacement` node list.  Glyph nodes corresponding to
-- <em>automatic</em> ligatures add to the characters of a word with the
-- glyph nodes found in their `components` node list.  This has some
-- implications:
--
--   <ul>
--
--   <li>While automatic ligatures are replaced by (the nodes of) their
--   constituting characters, a word in table representation can contain
--   ligatures if they are already present in the input stream.</li>
--
--   <li>Because any glyph node signals the beginning of a word even if
--   it corresponds to an automatic ligature without further glyph nodes
--   as components, this table (and the second one described below) can
--   be completely empty.</li>
--
--   </ul>
-- </li>
--
-- <li>Values in the second table are either `nil` or a table.  If it is
-- a table, the table at position k is a stack of parent nodes of the
-- node at position k.  Parent nodes are either discretionary nodes or
-- glyph nodes, the latter corresponding to an automatic ligature (node
-- contains a components field).</li>
--
-- </ol>
--
-- @return Iterator function.  Argument is a node list head.
local function words(head)

   -- Upvalue: Next node to investigate.
   local next_node = head

   return function ()
      local word_start
      local last
      local n = next_node
      while n do
         local nid = n.id
         if nid == GLYPH or nid == DISC then
               -- Initialize a new word?
            if not word_start then
               word_start = n
            end
         elseif (nid == WHATSIT and nsubtype == USER_DEFINED)
         then
            -- Ignore node.  Don't change state.
         else
            -- Process non-word node.
            if word_start then
               -- Save next node as upvalue.
               next_node = n.next
               -- Return current word.
               return word_start, last
            end
         end
         last = n
         n = n.next
      end
      next_node = nil
      if word_start then
         return word_start, last
      end
      return nil, nil
   end

end
M.words = words



return M
