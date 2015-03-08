## `Badger bits <https://github.com/gradha/badger_bits>`_ os helpers.
##
## Contains stuff which I would like to see in `os
## <http://nim-lang.org/os.html>`_ or is common to my code for some reason.

import os, strutils
export os

iterator dot_walk_dir_rec*(dir: string,
    filter = {pcFile, pcDir}): string {.tags: [ReadDirEffect].} =
  ## Version of os.walkDirRec which ignores items starting with a dot.
  ##
  ## Since a `fix <http://forum.nim-lang.org/t/514>`_ for `os.walkDirRec
  ## <http://nim-lang.org/os.html#walkDirRec>`_ won't come, this version simply
  ## ignores all directories and files starting with a dot.
  var stack = @[dir]
  while stack.len > 0:
    for k,p in walkDir(stack.pop()):
      if k in filter:
        case k
        of pcFile, pcLinkToFile:
          if p.find("/.") < 0:
            yield p
        of pcDir, pcLinkToDir:
          if p.find("/.") < 0:
            stack.add(p)
