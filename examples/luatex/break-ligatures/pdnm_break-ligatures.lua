-- -*- coding: utf-8 -*-
local unicode = require('unicode')
local cls_spot = require('cls_pdnm_spot')
local spot = cls_spot:new()

local Ncopy = node.copy
local Ncopy_list = node.copy_list
local Nflush_list = node.flush_list
local Ninsert_after = node.insert_after
local Ninsert_before = node.insert_before
local Nremove = node.remove
local Ntail = node.tail
local Ntraverse = node.traverse
local Uchar = unicode.utf8.char

local DISC = node.id('disc')
local GLYPH = node.id('glyph')


--- Check a hyphenation point for a wrong ligature and break it.
-- Two letters at a word or affix joint shouldn't form a ligature.  This
-- function checks if there is a ligature spanning the given word joint
-- and breaks it by manipulating the <code>replace</code> list of the
-- corresponding discretionary node.
--
-- @param a_parents Stack of parent nodes of first glyph (left of
-- joint).  Top element (with highest index) is the nearest parent node
-- of node a.  In code, all variables starting a?_ refer to the first
-- glyph.
-- @param b_parents Stack of parent nodes of second glyph (right of
-- joint).  Top element (with highest index) is the nearest parent node
-- of node b.  In code, all variables starting b?_ refer to the second
-- glyph.
-- @return Debug information: string or number.  The string indicates
-- the ligaturing situation found within the discretionaries replace
-- list.  A number is returned if no ligature could be found.
local function process_hyphenation(a_parents, b_parents)
   -- Do a and b have parents at all?
   if a_parents and b_parents then
      -- Are first parents of a and b equal?
      local ap_i = a_parents[#a_parents]
      local bp_i = b_parents[#b_parents]
      if ap_i == bp_i then
         -- Is parent a glyph node (ligature)?
         if ap_i.id == GLYPH then
            -- pattern <ab>
            --
            -- Is next common parent a discretionary?
            if #a_parents > 1 and #b_parents > 1 then
               local ap_ii = a_parents[#a_parents-1]
               if ap_ii.id == DISC then
                  -- pattern (xa-/by/x<ab>y) => (xa-/by/xaby)
                  -- example: auf/fordern
                  local head = ap_ii.replace
                  for n in Ntraverse(ap_i.components) do
                     local c = Ncopy(n)
                     head = Ninsert_before(head, ap_i, c)
                  end
                  head = Nremove(head, ap_i)
                  ap_ii.replace = head
                  ap_i.prev = nil
                  ap_i.next = nil
                  Nflush_list(ap_i)
                  return '(xa-/by/x<ab>y)'
               elseif ap_ii.id == GLYPH then
                  -- pattern <<ab>c>
                  --
                  -- Is next common parent a discretionary?
                  if #a_parents > 2 and #b_parents > 2 then
                     local ap_iii = a_parents[#a_parents-2]
                     if ap_iii.id == DISC then
                        -- pattern (xa-/<bc>y/x<<ab>c>y) => (xa-/<bc>y/xa<bc>y)
                        -- example: auf/<fi>nden
                        local last = Ntail(ap_iii.pre)
                        if last.id == GLYPH and Uchar(last.char) == '-' then
                           local head = Ncopy_list(ap_iii.pre, last)
                           last = Ntail(head)
                           for n in Ntraverse(ap_iii.post) do
                              local c = Ncopy(n)
                              head, last = Ninsert_after(head, last, c)
                           end
                           local old_replace = ap_iii.replace
                           ap_iii.replace = head
                           old_replace.prev = nil
                           Nflush_list(old_replace)
                           return '(xa-/<bc>y/x<<ab>c>y)'
                        else return 12
                        end
                     else return 11
                     end
                  else return 10
                  end
               else return 9
               end
            else return 8
            end
         else return 7
         end
      else-- Unequal first parents.
         -- Is second next parent of a equal to first parent of b?
         if #a_parents > 1 then
            local ap_ii = a_parents[#a_parents-1]
            if ap_ii == bp_i then
               if ap_ii.id == GLYPH then
                  -- pattern <<ca>b>
                  --
                  -- Is next common parent a discretionary?
                  if #a_parents > 2 and #b_parents > 1 then
                     local ap_iii = a_parents[#a_parents-2]
                     if ap_iii.id == DISC then
                        -- pattern (x<ca>-/by/x<<ca>b>y) => (x<ca>-/by/x<ca>by)
                        -- example: Rohsto<ff>/industrie
                        local head = ap_iii.replace
                        for n in Ntraverse(ap_ii.components) do
                           local c = Ncopy(n)
                           head = Ninsert_before(head, ap_ii, c)
                        end
                        head = Nremove(head, ap_ii)
                        ap_iii.replace = head
                        ap_ii.prev = nil
                        ap_ii.next = nil
                        Nflush_list(ap_ii)
                        return '(x<ca>-/by/x<<ca>b>y)'
                     else return 6
                     end
                  else return 5
                  end
               else return 4
               end
            else return 3
            end
         else return 2
         end
      end
   else return 1
   end
   return 0
end


--- Manipulation that breaks wrong ligatures.
-- This manipulation breaks wrong ligatures inserted by TeX's greedy
-- algorithm.  The manipulation has to be applied after TeX's ligaturing
-- stage.
--
-- @param head  Head of a node list.
-- @param twords  A sequence of word property tables.
local function apply_manipulation(head, twords)
   -- Iterate over words.
   for _, word in ipairs(twords) do
      -- Debug output.
      local w = {}
      for _, n in ipairs(word.nodes) do
         table.insert(w, Uchar(n.char))
      end
      local s = table.concat(spot:to_word_with_spots(w, word.levels))
      -- Check all valid spots.
      for pos, level in ipairs(word.levels) do
         -- Valid spot?
         if (level % 2) == 1 then
            -- Apply manipulation.
            local result = process_hyphenation(word.parents[pos-1], word.parents[pos])
            texio.write_nl('[word joint] ' .. s .. ' ' .. tonumber(pos-1) .. ':' .. tostring(result))
         end
      end
   end
end



-- Call-back registering.
--
-- Load padrinoma module.
local padrinoma = require('pdnm_nl_manipulation')
-- Create custom pattern matching function.
local scan_node_list = padrinoma.create_node_list_scanner('../../patterns/hyph-de-1901-joint.pat.txt', 'german', true)

local nlp = require('pdnm_nl_printer')
local printer = nlp.new_simple_printer('[node] ')

-- Register hyphenate call-back.
luatexbase.add_to_callback('ligaturing',
                           function (head, tail)
                              -- Apply regular ligaturing.
                              node.ligaturing(head)
                              printer(head)
                              -- Do pattern matching.
                              local twords = scan_node_list(head)
                              -- Apply node list manipulation.
                              apply_manipulation(head, twords)
                           end,
                           'pdnm_ligaturing')
