-- -*- coding: utf-8 -*-
local unicode = require('unicode')
local cls_spot = require('cls_pdnm_spot')
local spot = cls_spot:new()

local Ncopy = node.copy
local Nflush_list = node.flush_list
local Ninsert_before = node.insert_before
local Nremove = node.remove
local Ntraverse = node.traverse
local Uchar = unicode.utf8.char

local DISC = node.id('disc')
local GLYPH = node.id('glyph')


--- Break a ligature of the form <code>x<ab>y</code>.
-- Transformation is: x<ab>y => xaby.
--
-- @param head  List head.
-- @param lig  Ligature node within list.
-- @return List head (might have changed).
local function break_double_ligature(head, lig)
   -- Insert ligature components before ligature node.
   for n in Ntraverse(lig.components) do
      local c = Ncopy(n)
      head = Ninsert_before(head, lig, c)
   end
   -- Remove original ligature from node list.
   head = Nremove(head, lig)
   -- Destroy ligature node.
   lig.prev = nil
   lig.next = nil
   Nflush_list(lig)
   return head
end


--- Break a ligature of the form <code>x<<ab>c>y</code>.
-- Theoretical transformation is: x<<ab>c>y => xa<bc>y.  Due to lack of
-- <bc> ligaturing information, transformation is actually: x<<ab>c>y =>
-- xabcy, currently.
--
-- @param head  List head.
-- @param lig  Ligature node within list.
-- @return List head (might have changed).
local function break_triple_ligature(head, olig)
   local ilig = olig.components
   local a = ilig.components
   local b = a.next
   local c = ilig.next
   -- Insert new nodes before outer ligature.
   head = Ninsert_before(head, olig, Ncopy(a))
   head = Ninsert_before(head, olig, Ncopy(b))
   head = Ninsert_before(head, olig, Ncopy(c))
   -- Remove outer ligature from discretionary replace list.
   head = Nremove(head, olig)
   -- Destroy outer ligature node.
   olig.prev = nil
   olig.next = nil
   Nflush_list(olig)
   return head
end


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
local function process_hyphenation(head, a_parents, b_parents)
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
                  -- pattern x<ab>y within discretionary: (v/w/x<ab>y) => (v/w/xaby)
                  -- example: auf/fordern
                  ap_ii.replace = break_double_ligature(ap_ii.replace, ap_i)
                  return '(v/w/x<ab>y)'
               elseif ap_ii.id == GLYPH then
                  -- pattern <<ab>c>
                  --
                  -- Is next common parent a discretionary?
                  if #a_parents > 2 and #b_parents > 2 then
                     local ap_iii = a_parents[#a_parents-2]
                     if ap_iii.id == DISC then
                        -- pattern <<ab>c> within discretionary: (v/w/x<<ab>c>y) => (v/w/xa<bc>y)
                        -- example: auf/<fi>nden
                        ap_iii.replace = break_triple_ligature(ap_iii.replace, ap_ii)
                        return '(v/w/x<<ab>c>y)'
                     else return 11
                     end
                  else
                     -- pattern <<ab>c> outside discretionary: x<<ab>c>y => xa<bc>y
                     -- example: auf/<fi>nden
                     local new_head = break_triple_ligature(head, ap_ii)
                     assert(new_head == head)
                     return 'x<<ab>c>y'
                  end
               else return 9
               end
            else
               -- pattern x<ab>y outside discretionary: x<ab>y => xaby
               -- example: auf/fordern
               local new_head = break_double_ligature(head, ap_i)
               assert(new_head == head)
               return 'x<ab>y'
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
                        -- pattern <<ca>b> within discretionary: (v/w/x<<ca>b>y) => (v/w/x<ca>by)
                        -- example: Rohsto<ff>/industrie
                        ap_iii.replace = break_double_ligature(ap_iii.replace, ap_ii)
                        return '(v/w/x<<ca>b>y)'
                     else return 6
                     end
                  else
                     -- pattern <<ca>b> outside discretionary: x<<ca>b>y => x<ca>by
                     -- example: Rohsto<ff>/industrie
                     local new_head = break_double_ligature(head, ap_ii)
                     assert(new_head == head)
                     return 'x<<ca>b>y'
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
            local result = process_hyphenation(head, word.parents[pos-1], word.parents[pos])
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
local scan_node_list = padrinoma.create_node_list_scanner('german', '../../patterns/hyph-de-1901-joint.pat.txt', 2, 2, true)

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
