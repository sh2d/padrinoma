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

--- Construct pre node list for ck rule discretionary.
-- Given two nodes <code>12</code>, return a list <code>2'-</code>,
-- where <code>2'</code> is a copy of node <code>2</code>.
local function get_pre_of_ck(head, first, second)
   -- Make copy of k node.
   local glyph_k = Ncopy(second)
   glyph_k.attr = first.attr
   -- Make copy of c node, changing char to hyphen.
   local glyph_hyph = Ncopy(first)
   glyph_hyph.char = 0x2d
   -- Link both nodes.
   glyph_k.prev = nil
   Ninsert_after(glyph_k, glyph_k, glyph_hyph)
   return glyph_k
end

--- Construct pre node list for triple consonant rule discretionary.
-- Given two nodes <code>12</code>, return a list <code>1'1''-</code>,
-- where <code>1'</code> and <code>1''</code> are copies of node
-- <code>1</code>.
local function get_pre_of_triple_consonant(head, first, second)
   -- Make two copies of first node.
   local glyph_cons1 = Ncopy(first)
   local glyph_cons2 = Ncopy(first)
   -- Make copy of first node, changing char to hyphen.
   local glyph_hyph = Ncopy(first)
   glyph_hyph.char = 0x2d
   -- Link all three nodes.
   glyph_cons1.prev = nil
   Ninsert_after(glyph_cons1, glyph_cons1, glyph_cons2)
   Ninsert_after(glyph_cons1, glyph_cons2, glyph_hyph)
   return glyph_cons1
end

--- Apply a discretionary replacement.
-- Triple consonant rule as well as ck rule are handled uniformly: Two
-- nodes <code>12</code> are replaced by a
-- <code>\discretionary{.}{}{1}2</code>, where . is a rule specific
-- replacement.  A less invasive replacement exists for the case of
-- triple consonant rule, but uniform handling of both rules allows for
-- better code sharing.
--
-- @param head  Head of a node list.
-- @param twords  A sequence of word property tables.
local function nstd_hyph(head, twords)
   for _, word in ipairs(twords) do
      -- Only process words not containing explicit hyphens.
      if not word.exhyphenchars then
         for pos, level in ipairs(word.levels) do
            -- Spot with surrounding top-level glyph nodes?
            if (level % 2 == 1) and not word.parents[pos-1] and not word.parents[pos] then
               local first = word.nodes[pos-1]
               local second = word.nodes[pos]
               -- Create discretionary node.
               local d = Nnew(DISC, 0)
               d.attr = first.attr
               -- Sub-list .pre:
               if Uchar(TEXgetlccode(first.char)) == 'c' then
                  d.pre = get_pre_of_ck(head, first, second)
               else
                  d.pre = get_pre_of_triple_consonant(head, first, second)
               end
               local prefirst = first.prev
               local presecond = second.prev
               -- Sub-list .replace:
               --
               -- Unlink list (first)--(second.prev).
               prefirst.next = second
               second.prev = prefirst
               -- And put it into .replace field.
               first.prev = nil
               presecond.next = nil
               d.replace = first
               -- Insert discretionary before second node.
               Ninsert_before(head, second, d)
            end
         end
      end
   end
end

return nstd_hyph
