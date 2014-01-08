-- -*- coding: utf-8 -*-
local unicode = require('unicode')
local nli = require('pdnm_node_list_iterate_words')



local Ntraverse = node.traverse
local Sformat = string.format
local Tconcat = table.concat
local Tinsert = table.insert
local Uchar = unicode.utf8.char



local DISC = node.id('disc')
local GLYPH = node.id('glyph')



--- Collect characters from glyph nodes in a node list.
--
-- @param head  Node list.
-- @parem t  Table to insert characters.
local function process_list(head, t)
   -- Iterate over all nodes in the list.
   for n in Ntraverse(head) do
      local nid = n.id
      if nid == GLYPH then
         -- Fundamental glyph or automatic ligature?
         local components = n.components
         if not components then
            -- Fundamental glyph.
            --
            -- Add node to table.
            Tinsert(t, Uchar(n.char))
         else
            -- Automatic ligature.
            --
            -- Update parent node stack and recurse into component
            -- node list.
            Tinsert(t, '<')
            process_list(components, t)
            Tinsert(t, '>')
         end
      elseif nid == DISC then
         -- Does the discretionary contain components belonging to a
         -- non-hyphenated word?
         local replace = n.replace
         if replace then
            -- Update parent node stack and recurse into replacment
            -- node list.
            Tinsert(t, '{')
            process_list(replace, t)
            Tinsert(t, '}')
         end
      end
   end
end



local function print_word(start, stop)
   local t = {}
   local stop_next = stop.next
   stop.next = nil
   process_list(start, t)
   stop.next = stop_next
   texio.write(Sformat('[word] %s\n', Tconcat(t)))
end



local function cb(head)
   for start, stop in nli.words(head) do
      print_word(start, stop)
   end
   lang.hyphenate(head)
   return true
end



luatexbase.add_to_callback('hyphenate', cb, 'test_h')
--luatexbase.add_to_callback('ligaturing', cb, 'test_l')
--luatexbase.add_to_callback(kerning, cb, 'test_k')
--luatexbase.add_to_callback('pre_linebreak_filter', cb, 'test_pre')
--luatexbase.add_to_callback('post_linebreak_filter', cb, 'test_post')
