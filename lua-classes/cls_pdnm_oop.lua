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



--- This module implements a basic class for a proto-type based approach
-- of object-orientation in Lua.  It is based on the approach presented
-- in the book <em>Programming in Lua</em> by R. Ierusalimschy, of which
-- the first edition is also <a
-- href='http://www.lua.org/pil/contents.html/'>available online</a>.<br
-- />
--
-- Every object (class or instance) derived from this class provides at
-- least three fields:
--
-- <dl>
-- <dt><code>super</code></dt>
-- <dd><em>(variable)</em>&emsp;A reference to the parent (proto-type)
-- class.</dd>
-- <dt><code>new(self, o)</code></dt>
-- <dd><em>(function)</em>&emsp;Creates a new instance of the calling
-- (parent) class.  First argument is a parent class.  Second argument
-- is a table which should be used as the new instance.  Instances are
-- usually created by calling:&emsp;<code>obj =
-- <em>parent</em>:new()</code></dd>
-- <dt><code>init(self)</code></dt>
-- <dd><em>(function)</em>&emsp;Initializes an instance.  This method is
-- automatically called for every instance created by
-- <code>new()</code>.  Argument is the newly created instance.
-- Initialization can be chained by calling
-- <code><em>parent</em>.super.init(self)</code> within
-- <code>init()</code>, usually as the first operation.</dd>
-- </dl>
--
--
-- @class module
-- @name cls_pdnm_oop
-- @author Stephan Hennig
-- @copyright 2013, Stephan Hennig

-- API-Dokumentation can be generated via <pre>
--
--   luadoc -d API *.lua
--
-- </pre>



-- @trick Prevent LuaDoc from looking past here for module description.
--[[ Trick LuaDoc into entering 'module' mode without using that command.
module(...)
--]]
-- Local module table.
local M = {}



--- Initialize object.
--
-- @param self  Callee reference.
local function init(self)
end
M.init = init



--- Constructor.
--
-- @param self  Callee reference.
-- @param o  Optional existing object.
-- @return A new trie object.
local function new(self, o)
   -- Create object.
   o = o or {}
   -- Set metatable to parent class.
   setmetatable(o, self)
   self.__index = self
   -- Reference to parent class.
   o.super = self
   -- Initialize new object.
   o:init()
   return o
end
M.new = new



-- Export module table.
return M
