-- -*- coding: utf-8 -*-
local unicode = require('unicode')

local Ncopy = node.copy
local Nfree = node.free
local Ninsert_after = node.insert_after
local Ninsert_before = node.insert_before
local Nnew = node.new
local Nremove = node.remove
local TEXgetlccode = tex.getlccode
local Uchar = unicode.utf8.char

local DISC = node.id('disc')
local GLYPH = node.id('glyph')

local function ck(head, tnode, tparent, tlevels)
   for pos, level in ipairs(tlevels) do
      local first = tnode[pos-1]
      local second = tnode[pos]
      if (level % 2 == 1)
         and not tparent[pos-1] and not tparent[pos]
         and Uchar(TEXgetlccode(first.char)) == 'c' and Uchar(TEXgetlccode(second.char)) == 'k'
      then
         -- Pre sub-list:
         --
         -- Make copy of k node.
         local pre1 = Ncopy(second)
         pre1.attr = first.attr
         -- Make copy of c node, changing char to hyphen.
         local pre2 = Ncopy(first)-- hyphen character
         pre2.char = 0x2d
         -- Link both nodes.
         pre2.prev = pre1
         pre2.next = nil
         pre1.prev = nil
         pre1.next = pre2
         -- Replace sub-list:
         --
         -- Copy of c node.
         local repl1 = Ncopy(first)
         repl1.prev = nil
         repl1.next = nil
         -- Create discretionary node.
         local d = Nnew(DISC, 0)
         d.attr = first.attr
         d.pre = pre1
         d.replace = repl1
         -- Insert discretionary before c node.
         Ninsert_before(head, first, d)
         local count = 0
         local n = first
         -- Remove c node and everything before k node.
         repeat
            count = count + 1
            local next
            head, next = Nremove(head, n)
            Nfree(n)
            n = next
         until n == second
         if count > 1 then
            texio.write(count .. ' nodes removed from list\n')
         end
      end
   end
end

return ck
