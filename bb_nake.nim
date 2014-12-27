## `Badger bits <https://github.com/gradha/badger_bits>`_ nake helpers.
##
## Contains stuff `nakefiles <https://github.com/fowlmouth/nake>`_ code.

import
  nake, os, bb_system, osproc, parseopt, rdstdin, strutils, tables


type
  Shell_failure* = object of EAssertionFailed ## \
    ## Indicates something failed, with error output if `errors` is not nil.
    errors*: string

const
  sybil_witness* = ".sybil_systems"
  dist_dir* = "dist"


proc cp*(src, dest: string) =
  ## Verbose wrapper around copy_file_with_permissions.
  ##
  ## In addition to copying permissions this will create necessary destination
  ## directories. If `src` is a directory it will be copied recursively.
  assert src.not_nil and dest.not_nil
  assert src != dest
  echo src & " -> " & dest
  let base_dir = dest.split_file.dir
  if base_dir.len > 0:
    base_dir.create_dir

  if src.exists_dir:
    src.copy_dir(dest)
  else:
    src.copy_file_with_permissions(dest)


proc test_shell*(cmd: varargs[string, `$`]): bool {.discardable.} =
  ## Like dire_shell() but doesn't quit, rather raises `Shell_failure
  ## <#Shell_failure>`_.
  let
    full_command = cmd.join(" ")
    (output, exit) = full_command.exec_cmd_ex
  result = 0 == exit
  if not result:
    var e = new_exception(Shell_failure, "Error running " & full_command)
    e.errors = output
    raise e


export cd
export defaultTask
export direShell
export listTasks
export needsRefresh
export os
export parseopt
export rdstdin
export runTask
export shell
export strutils
export tables
export task
export withDir
