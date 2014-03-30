-- -*- coding: utf-8 -*-

local unicode = require('unicode')
local cls_pattern = require('cls_pdnm_pattern')

local Ulen = unicode.utf8.len
local Ulower = unicode.utf8.lower


-- Module table.
local M = cls_pattern:new()


local function cb_pdnm_pattern__decomposition_start(self)
   local len = #self.word + 2-- plus boundary letters
   -- Update word length counter.
   self.count_length[len] = (self.count_length[len] or 0) + 1
   -- Remember maximum string length processed.
   if len < self.count_length.min then self.count_length.min = len end
   if len > self.count_length.max then self.count_length.max = len end
   -- If necessary, create and initialise array of activity distribution
   -- for current length.
   local distribution = self.distribution[len]
   if not distribution then
      distribution = {}
      for i = 1,len do
         distribution[i] = 0
      end
      self.distribution[len] = distribution
   end
end
M.cb_pdnm_pattern__decomposition_start = cb_pdnm_pattern__decomposition_start


local function cb_pdnm_pattern__decomposition_pre_iterate_active_tries(self)
   local len = #self.word + 2-- plus boundary letters
   local pos = self.letter_pos
   self.distribution[len][pos] = self.distribution[len][pos] + #self.active
end
M.cb_pdnm_pattern__decomposition_pre_iterate_active_tries = cb_pdnm_pattern__decomposition_pre_iterate_active_tries


local function write_distribution(self, start, stop)
   local fname
   if stop then
      fname = 'data.' .. tostring(start) .. '_' .. tostring(stop)
   elseif start then
      stop = start
      fname = 'data.' .. tostring(start)
   else
      start = self.count_length.min
      stop = self.count_length.max
      fname = 'data.0'
   end
   assert((self.count_length.min <= start) and (start <= stop) and (stop <= self.count_length.max))
   -- Initialize missing distribution tables and length counters.
   for len = self.count_length.min,self.count_length.max do
      local distribution = self.distribution[len]
      if not distribution then
         distribution = {}
         for pos = 1,len do
            distribution[pos] = 0
         end
         self.distribution[len] = distribution
      end
      self.count_length[len] = self.count_length[len] or 0
   end
   -- Output distribution.
   local fout = assert(io.open(fname, 'w'))
   -- Iterate over all possible string positions.
   for pos = 1,stop do
      -- Cumulate over all valid string lengths (larger than start and pos).
      local cum_distribution = 0
      local cum_count = 0
      for len = math.max(start,pos),stop do
         -- All array accesses are valid (see above).
         cum_distribution = cum_distribution + self.distribution[len][pos]
         cum_count = cum_count + self.count_length[len]
      end
      fout:write(pos, ' ', cum_distribution / cum_count, '\n')
   end
   fout:close()
end
M.write_distribution = write_distribution


local function log_active(self, s)
   local word = self:to_word(Ulower(s))
   self:decompose(word)
end
M.log_active = log_active


local function record_to_value(self, pattern)
   return true
end


local function init(self)
   M.super.init(self)
   self.count_length = { min = math.huge, max = -1 }
   self.distribution = {}
   self.count = {}
   self.trie.record_to_value = record_to_value
end
M.init = init


return M
