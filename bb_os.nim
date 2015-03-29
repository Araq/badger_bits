## `Badger bits <https://github.com/gradha/badger_bits>`_ os helpers.
##
## Contains stuff which I would like to see in `os
## <http://nim-lang.org/os.html>`_ or is common to my code for some reason.

import os, strutils
export os


when defined(windows):
  import winlean
elif defined(posix):
  import posix


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


iterator dot_walk_dir*(dir: string):
    tuple[kind: PathComponent, path: string] {.tags: [ReadDirEffect].} =
  ## Version of os.walkDir which ignores items starting with a dot.
  ##
  ## The windows version will report files with a dot.
  when defined(windows):
    var f: TWIN32_FIND_DATA
    var h = findFirstFile(dir / "*", f)
    if h != -1:
      while true:
        var k = pcFile
        if not skipFindData(f):
          if (f.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32:
            k = pcDir
          if (f.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32:
            k = succ(k)
          yield (k, dir / extractFilename(getFilename(f)))
        if findNextFile(h, f) == 0'i32: break
      findClose(h)
  else:
    var d = opendir(dir)
    if d != nil:
      while true:
        var x = readdir(d)
        if x == nil: break
        var y = $x.d_name
        if y[0] != '.' and y != "..":
          var s: TStat
          y = dir / y
          if lstat(y, s) < 0'i32: break
          var k = pcFile
          if S_ISDIR(s.st_mode): k = pcDir
          if S_ISLNK(s.st_mode): k = succ(k)
          yield (k, y)
      discard closedir(d)
