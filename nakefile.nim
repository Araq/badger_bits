import
  bb_nake, lazy_rest, bb_system, sequtils, osproc


type
  Failed_test = object of EAssertionFailed ## \
    ## Indicates something failed, with error output if `errors` is not nil.
    errors*: string


const
  pkg_name = "lazy_rest"
  badger_name = "lazy_rest_badger"
  src_name = "c-sources"
  bin_name = pkg_name & "-" & lazy_rest.version_str & "-binary"
  badger = "lazy_rest_bager.nim"


template glob(pattern: string): expr =
  ## Shortcut to simplify getting lists of files.
  to_seq(walk_files(pattern))

let
  rst_files = concat(glob("*.rst"), glob("docs"/"*rst"))
  nim_files = concat(glob("*.nim"))

iterator all_html_files(files: seq[string]): tuple[src, dest: string] =
  for filename in files:
    var r: tuple[src, dest: string]
    r.src = filename
    # Ignore files if they don't exist, nimble version misses some.
    if not r.src.exists_file:
      echo "Ignoring missing ", r.src
      continue
    r.dest = filename.change_file_ext("html")
    yield r


proc test_shell(cmd: varargs[string, `$`]): bool {.discardable.} =
  ## Like dire_shell() but doesn't quit, rather raises an exception.
  let
    full_command = cmd.join(" ")
    (output, exit) = full_command.exec_cmd_ex
  result = 0 == exit
  if not result:
    var e = new_exception(Failed_test, "Error running " & full_command)
    e.errors = output
    raise e


proc rst_to_html(src, dest: string): bool =
  ## Generates an HTML file from `src` into `dest`.
  if not dest.needs_refresh(src): return
  echo src & " -> " & dest
  test_shell(nim_exe, "rst2html --verbosity:0", src)
  result = true


proc doc(start_dir = ".", open_files = false) =
  ## Generate html files from the rst docs.
  ##
  ## Pass `start_dir` as the root where you want to place the generated files.
  ## If `open_files` is true the ``open`` command will be called for each
  ## generated HTML file.
  for rst_file, html_file in rst_files.all_html_files:
    let
      full_path = start_dir / html_file
      base_dir = full_path.split_file.dir
    base_dir.create_dir
    if not full_path.needs_refresh(rst_file): continue
    if not rst_to_html(rst_file, full_path):
      quit("Could not generate html doc for " & rst_file)
    else:
      if open_files: shell("open " & full_path)

  for nim_file, html_file in nim_files.all_html_files:
    let
      full_path = start_dir / html_file
      base_dir = full_path.split_file.dir
    base_dir.create_dir
    if not full_path.needs_refresh(nim_file): continue
    if not shell(nim_exe, "doc --verbosity:0 -o:" & full_path, nim_file):
      quit("Could not generate HTML API doc for " & nim_file)
    echo full_path
    if open_files: shell("open " & full_path)

  echo "All docs generated"


proc doco() = doc(open_files = true)


proc validate_doc() =
  for rst_file, html_file in rst_files.all_html_files():
    echo "Testing ", rst_file
    let (output, exit) = execCmdEx("rst2html.py " & rst_file & " > /dev/null")
    if output.len > 0 or exit != 0:
      echo "Failed python processing of " & rst_file
      echo output

proc clean() =
  for path in walk_dir_rec("."):
    let ext = splitFile(path).ext
    if ext == ".html" or ext == ".idx" or ext == ".exe":
      echo "Removing ", path
      path.removeFile()
  echo "Temporary files cleaned"


proc install_nimble() =
  direshell("nimble install -y")
  echo "Installed"


proc run_tests() =
  run_test_subdirectories("tests")


proc web() =
  echo "Changing branches to render gh-pages…"
  let ourselves = read_file("nakefile")
  dire_shell "git checkout gh-pages"
  dire_shell "rm -R `git ls-files -o`"
  dire_shell "rm -Rf gh_docs"
  dire_shell "gh_nimrod_doc_pages -c ."
  write_file("nakefile", ourselves)
  dire_shell "chmod 775 nakefile"
  echo "All commands run, now check the output and commit to git."
  shell "open index.html"
  echo "Wen you are done come back with './nakefile postweb'."


proc postweb() =
  echo "Forcing changes back to master."
  dire_shell "git checkout -f @{-1}"
  echo "Updating submodules just in case."
  dire_shell "git submodule update"


task "clean", "Removes temporal files, mostly.": clean()
task "doc", "Generates HTML docs.": doc()
task "i", "Uses nimble to force install package locally.": install_nimble()
task "test", "Runs local generation tests.": run_tests()
task "web", "Renders gh-pages, don't use unless you are gradha.": web()
task "check_doc", "Validates rst format with python.": validate_doc()
task "postweb", "Gradha uses this like portals, don't touch!": postweb()

when defined(macosx):
  task "doco", "Like 'doc' but also calls 'open' on generated HTML.": doco()
