## `Badger bits <https://github.com/gradha/badger_bits>`_ nake helpers.
##
## Contains stuff `nakefiles <https://github.com/fowlmouth/nake>`_ code.

import
  nake, os, bb_system, osproc, parseopt, rdstdin, strutils, tables, sequtils


type
  Shell_failure* = object of EAssertionFailed ## \
    ## Indicates something failed, with error output if `errors` is not nil.
    errors*: string

const
  sybil_witness* = ".sybil_systems"
  dist_dir* = "dist"
  vagrant_linux_dir* = "vagrant_linux"


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


proc copy_vagrant*(dest: string) =
  ## Copies the current git files to `dest`/``software``.
  ##
  ## The files to copy are found out with ``git ls-files -c``. The
  ## `sybil_witness <#sybil_witness>`_ witness will be created at `dest`.
  let
    dest = dest/"software"
    paths = filter_it(to_seq(
      exec_cmd_ex("git ls-files -c").output.split_lines), it.exists_file)

  dest.remove_dir
  for path in paths:
    cp(path, dest/path)
  write_file(dest/sybil_witness, "dominator")


proc build_vagrant*(vagrant_dir, remote_shell_commands: string) =
  ## Powers up the vagrant box in the specified dir to run some commands.
  ##
  ## Use this to run system commands to build the binaries in the vagrant
  ## machine. The `remote_shell_commands` parameter is meant to be a string
  ## that will be embedded inside a shell command, so you can run several
  ## commands with ``&&``. Example:
  ##
  ## .. code-block::
  ##   build_vagrant("dir", "nake test && nimble build && nake install")
  ##
  ## Alternatively you can pass a multiline string, where each newline will be
  ## replaced with double ampersands. Equivalent example:
  ##
  ## .. code-block::
  ##   build_vagrant("dir", """
  ##     nake test
  ##     nimble build
  ##     nake install""")
  ##
  ## The commands will be run in the ``/vagrant/software`` directory, populated
  ## previously by `copy_vagrant() <#copy_vagrant>`_.  After all work has done
  ## the vagrant instance is halted. This doesn't do any provisioning, the
  ## vagrant instances are meant to be prepared beforehand.
  var commands = remote_shell_commands
  if commands.find(NewLines) >= 0:
    # Split into lines, strip and merge with ampersands.
    var multi = commands.split_lines
    multi.map_it(it.strip)
    multi = multi.filter_it(it.len > 0)
    commands = multi.join(" && ")

  with_dir vagrant_dir:
    dire_shell "vagrant up"
    dire_shell("vagrant ssh -c '" &
      "cd /vagrant/software && " & commands & " && " &
      "echo done'")
    dire_shell "vagrant halt"


proc run_vagrant*(remote_shell_commands: string, dirs: seq[string] = nil) =
  ## Takes care of running some shell commands in the specified vagrant dirs.
  ##
  ## Pass the directories where vagrant bootstrap files are to be copied. If
  ## you pass nil, the proc will iterate over all the directories found under
  ## `vagrant_linux_dir <#vagrant_linux_dir>`_. The `remote_shell_commands` is
  ## the shell string to be run for each vm, see `build_vagrant()
  ## <#build_vagrant>`_.
  var dirs = dirs
  if dirs.is_nil:
    dirs = @[]
    for kind, path in vagrant_linux_dir.walk_dir:
      if kind == pcDir or kind == pcLinkToDir:
        dirs.add(path)

  for dir in dirs:
    cp(vagrant_linux_dir/"bootstrap.sh", dir/"bootstrap.sh")
    copy_vagrant dir
    build_vagrant(dir, remote_shell_commands)


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
