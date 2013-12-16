#!/bin/sh
#-- -*- coding: utf-8 -*-

texlua active_tries.lua $*
if test $? -ne 0
then
  exit 1
fi
#~ Cummulated mean number of active tries.
mpost nul "newinternal letters; letters:=0; input diagram.mp"
#~ Cummulated mean number of active tries by word length.
for i in {6..37}
do
  mpost nul "newinternal letters; letters:=$i; input diagram.mp"
done
