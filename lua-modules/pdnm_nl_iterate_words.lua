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
-- The iterator function returnes the words found in the given node list
-- one by one.  A word is a series of consecutive nodes of type `glyph`
-- or `disc`.  For every word, first and last node are returned.<br />
--
-- This iterator doesn't fully comply with TeX's notion of words subject
-- to hyphenation.  As an example, words next to an <code>\hbox</code>
-- aren't hyphenated by TeX and changes in the language imply word
-- boundaries.  Here's a link to <a
-- href="https://foundry.supelec.fr/scm/viewvc.php/trunk/source/texk/web2c/luatexdir/lang/texlang.w?root=luatex&view=markup">the
-- relevant LuaTeX C source code</a>.  See <a
-- href="http://tug.org/pipermail/tex-hyphen/2014-January/001071.html">this
-- mail</a> on the tex-hyphen list.
--
-- @param head  Node list to traverse.
-- @return Iterator function.
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
