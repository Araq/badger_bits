## `Badger bits <https://github.com/gradha/badger_bits>`_ nake helpers.
##
## Contains common `nake <https://github.com/fowlmouth/nake>`_ helpers.

import
  nake, os, bb_system, osproc, parseopt, rdstdin, strutils, tables, sequtils,
  algorithm, md5


type
  Shell_failure* = object of EAssertionFailed ## \
    ## Indicates something failed, with error output if `errors` is not nil.
    ##
    ## Raised by `test_shell() <#test_shell>`_.
    errors*: string

const
  sybil_witness* = ".sybil_systems" ## \
  ## Special witness filename used sometimes to hide nake developer commands.
  dist_dir* = "dist" ## \
  ## Directory where final binaries are placed for collection.
  vagrant_linux_dir* = "vagrant_linux" ## \
  ## Directory were vagrant configuration files and vm instances are stored.
  zip_exe* = "zip" ## \
  ## Name of the platform specific command used to create zip files.
  software_dir* = "software" ## \
  ## Name of the directory used to communicate with vagrant instances.
  exec_options = {poStdErrToStdOut, poUsePath, poEchoCmd}
  nimcache_dir* = "nimcache" ## \
  ## Name of the nimcache directory.


template glob*(pattern: string): expr =
  ## Familiar `os.walkFiles() <http://nim-lang.org/os.html#walkFiles>`_ shortcut
  ## to simplify getting lists of files.
  to_seq(walk_files(pattern))


proc cp*(src, dest: string) =
  ## Verbose wrapper around `os.copyFileWithPermissions()
  ## <http://nim-lang.org/os.html#copyFileWithPermissions>`_.
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
    src.copy_dir_with_permissions(dest)
  else:
    src.copy_file_with_permissions(dest)


proc test_shell*(cmd: varargs[string, `$`]): bool {.discardable.} =
  ## Like nake's ``direShell()`` but doesn't `system.quit()
  ## <http://nim-lang.org/system.html#quit>`_, instead raises `Shell_failure
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
  ## Copies the current git files to `dest`/`software_dir <#software_dir>`_.
  ##
  ## The files to copy are found out with ``git ls-files -c``. The
  ## `sybil_witness <#sybil_witness>`_ witness will be created at `dest`.
  let
    dest = dest/software_dir
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
  ## The commands will be run in the ``/vagrant``/`software_dir
  ## <#software_dir>`_ directory, populated previously by `copy_vagrant()
  ## <#copy_vagrant>`_.  After all work has done the vagrant instance is
  ## halted. This doesn't do any provisioning, the vagrant instances are meant
  ## to be prepared beforehand.
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
      "cd /vagrant/" & software_dir & " && " & commands & " && " &
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
      if kind == pcFile:
        continue
      dirs.add(path)

  for dir in dirs:
    let boot_file = vagrant_linux_dir/"bootstrap.sh"
    if boot_file.exists_file: boot_file.cp(dir/extract_filename(boot_file))
    copy_vagrant dir
    build_vagrant(dir, remote_shell_commands)


proc pack_dir*(zip_dir: string, do_remove = true) =
  ## Creates a zip out of `zip_dir`, then optionally removes that dir.
  ##
  ## The zip will be created in the parent directory with the same name as the
  ## last directory plus the zip extension.
  assert zip_dir.exists_dir
  let base_dir = zip_dir.split_file.dir
  with_dir base_dir:
    let
      local_dir = zip_dir.extract_filename
      zip_file = local_dir & ".zip"
    discard exec_process(zip_exe, args = ["-9r", zip_file, local_dir],
      options = exec_options)
    doAssert exists_file(zip_file)
    if do_remove:
      local_dir.remove_dir


proc collect_vagrant_dist*() =
  ## Takes dist generated files from vagrant dirs and copies to our `dist_dir
  ## <#dist_dir>`_.
  ##
  ## This requires that both vagrant' and current dist_dirs exists.
  doAssert dist_dir.exists_dir
  for kind, vagrant_dir in vagrant_linux_dir.walk_dir:
    if kind == pcFile:
      continue

    let vagrant_dist = vagrant_dir/software_dir/dist_dir
    for path in glob(vagrant_dist/"*"):
      cp(path, dist_dir/path.extract_filename)


proc switch_to_gh_pages*(ini_path_or_dir = ".") =
  ## Forces changing git branch to ``gh-pages`` and running
  ## ``gh_nimrod_doc_pages``.
  ##
  ## **This is a potentially destructive action!**. Pass the directory where
  ## the ``gh_nimrod_doc_pages.ini`` file lives, or the path to the specific
  ## file if you renamed it.
  assert ini_path_or_dir.not_nil
  echo "Changing branches to render gh-pages…"
  let ourselves = read_file("nakefile")
  dire_shell "git checkout gh-pages"
  # Keep ingored files http://stackoverflow.com/a/3801554/172690.
  shell "rm -Rf `git ls-files --others --exclude-standard`"
  shell "rm -Rf gh_docs"
  dire_shell "gh_nimrod_doc_pages -c " & ini_path_or_dir
  write_file("nakefile", ourselves)
  write_file(sybil_witness, "dominator")
  dire_shell "chmod 775 nakefile"
  echo "All commands run, now check the output and commit to git."
  shell "open index.html"
  echo "Wen you are done come back with './nakefile postweb'."


proc switch_back_from_gh_pages*() =
  ## Counterpart of `switch_to_gh_pages <#switch_to_gh_pages>`_.
  echo "Forcing changes back to master."
  dire_shell "git checkout -f @{-1}"
  echo "Updating submodules just in case."
  dire_shell "git submodule update"
  remove_dir("gh_docs")


proc show_md5_for_github*(templ: string) =
  ## Computes `md5 <http://nim-lang.org/md5.html>`_ for files in `dist_dir
  ## <#dist_dir>`_.
  ##
  ## The output will be displayed in a markdown template which includes the
  ## current git commit hash. To obtain the nim commit a ``git`` command is
  ## run in the parent ``root`` directory, which should point to the current
  ## compiler checkout. The following positional strings can be used in
  ## `templ`:
  ##
  ## * nim git commit (if possible).
  assert templ.not_nil
  var git_commit = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  let (output, code) = exec_cmd_ex("cd ../root && git log -n 1 --format=%H")
  if code == 0 and output.strip.len == 40:
    git_commit = output.strip
  echo templ % [git_commit]

  var files = to_seq(walk_files(dist_dir/"*.zip"))
  files.sort(system.cmp)
  for filename in files:
    let v = filename.read_file.get_md5
    echo "* ``", v, "`` ", filename.extract_filename


proc warn_babel_package() =
  ## Attempts to detect a babel package installed, to warn about conflicts.
  let files = concat(glob("*.nimble"), glob("*.babel"))
  if files.len != 1:
    if files.len > 1:
      echo "Warning, too maby `spec` files?"
    return

  let name = files[0].change_file_ext("")
  echo "Detected nimble package '", name, "'"
  let (output, code) = exec_cmd_ex("nimble path " & name)
  if code != 0:
    echo "Warning, ``nimble path " & name & "`` returned non zero!"
    return

  for raw_line in output.split_lines:
    let dir = raw_line.strip
    if dir.exists_dir:
      echo "Warning, package installed at ", dir
      echo "This could affect test results…"


proc run_test_subdirectories*(test_dir: string) =
  ## Compiles and runs files in the specified test directory.
  ##
  ## Inside the `test_dir` you need to have separate directories for each test,
  ## and each of these directories has to have a ``test*.nimrod.cfg`` file,
  ## which will be used to compile and run the test. If any of the tests fails
  ## this proc will quit.
  warn_babel_package()

  var failed: tuple[debug, release: seq[string]]
  failed.debug = @[]
  failed.release = @[]
  # Run the test suite.
  for test_file in walk_files(test_dir/"*/test_*.nimrod.cfg"):
    let
      name1 = test_file.split_file.name.change_file_ext("")
      name2 = name1.change_file_ext("nim")
      dir = test_file.parent_dir

    if not exists_file(dir/name2):
      echo "Not found ", dir/name2
      continue

    with_dir test_file.parent_dir:
      try:
        nimcache_dir.remove_dir
        echo "Testing ", name2, " in debug mode"
        #test_shell(nim_exe, " c --noBabelPath -r ", name2)
        test_shell(nim_exe, " c -d:debug -r ", name2)
      except Shell_failure:
        failed.debug.add(test_file)
      try:
        nimcache_dir.remove_dir
        echo "Testing ", name2, " in release mode"
        test_shell(nim_exe, " c -d:release -r ", name2)
      except Shell_failure:
        failed.release.add(test_file)

  # Show results
  if failed.debug.len > 0 or failed.release.len > 0:
    echo "Uh oh, " & $(failed.debug.len + failed.release.len) & " tests failed"
    for f in failed.debug: echo "\tdebug " & f
    for f in failed.release: echo "\trelease " & f
    quit(QuitFailure)
  else:
    echo "All tests run without errors."


export cd
export defaultTask
export direShell
export listTasks
export needsRefresh
export nimExe
export os
export parseopt
export rdstdin
export runTask
export shell
export strutils
export tables
export task
export withDir
