import
  bb_system, bb_os, sequtils, algorithm, strutils, bb_nake


proc test_not_nil() =
  var s: string
  do_assert s.is_nil
  s = ""
  do_assert(not s.is_nil)
  do_assert s.not_nil
  s = nil


proc test_dot_walk_dir_rec() =
  const
    dir = "dot_walk_dir_rec"
    good_result = [
      "dot_walk_dir_rec/this_also",
      "dot_walk_dir_rec/this_yes",
      "dot_walk_dir_rec/valid_dir/a",
      "dot_walk_dir_rec/valid_dir/b"]
    bad_result = [
      "dot_walk_dir_rec/.ignore_dir/invisible",
      "dot_walk_dir_rec/.ignore_dir/maybe_not",
      "dot_walk_dir_rec/.ignore_this_file",
      "dot_walk_dir_rec/this_also",
      "dot_walk_dir_rec/this_yes",
      "dot_walk_dir_rec/valid_dir/.ignore_this_file",
      "dot_walk_dir_rec/valid_dir/a",
      "dot_walk_dir_rec/valid_dir/b"]

  var l = to_seq(dir.dot_walk_dir_rec)
  l.sort(system.cmp)
  do_assert l == @good_result
  do_assert l != @bad_result
  l = to_seq(dir.walk_dir_rec)
  l.sort(system.cmp)
  do_assert l == @bad_result
  do_assert l != @good_result


proc test_exceptions() =
  proc badIO() =
    raise newException(EIO, "Bad IO")

  proc badMath() =
    raise newException(EArithmetic, "Bad addition")

  try:
    badMath()
  except:
    evar m, EArithmetic
    evar i, EIO
    echo "auto: Is arithmetic? ", (not m.isNil)
    echo "auto: Is IO? ", (not i.isNil)
    do_assert m.not_nil
    do_assert i.is_nil

  try:
    badIO()
  except EIO:
    elet EIO
    echo "auto: ", type(e), " ", e.msg

  try:
    badIO()
  except EIO:
    evar e, EArithmetic
    echo "auto: ", type(e)

  try:
    badIO()
  except EIO, EArithmetic:
    evar e, EIO
    echo "auto: ", type(e)

  echo "auto: finished"

proc test_safe_object() =
  type Node = ref object
    child: Node
  var parent = Node(
    child: Node(
      child: Node(
        child: nil)))

  var a = parent?.child?.child
  var b = parent?.child?.child?.child
  var c = parent?.child?.child?.child?.child

  do_assert a != nil
  do_assert b == nil
  do_assert c == nil

proc test_safe_string() =
  var
    a: string
    b = "something"

  do_assert b.last == 'g'

  proc doStuff(s: string) =
    do_assert s.safe.len > 0, "You need to pass a non empty string!"
    echo "doStuff"

  echo "Testing safe strings"
  echo b.safe
  echo b.safe.len
  echo a.safe
  echo a.nil_echo
  echo a.safe.len
  try:
    a.doStuff
    quit "Hey, we meant to assert there"
  except EAssertionFailed:
    echo "Tested assertion"

proc test_safe_seq() =
  var
    a: seq[string]
    b = @["a", "b"]

  do_assert b.last == "b"

  proc doStuff(s: seq[string]) =
    do_assert s.safe.len > 0, "You need to pass a non empty sequence!"
    echo "doStuff"

  echo "a: ", a.safe.join(", ")
  echo "a len: ", a.safe.len
  echo "b: ", b.safe.join(", ")
  echo "b len: ", b.safe.len
  try:
    a.doStuff
    quit "Hey, we meant to assert there"
  except EAssertionFailed:
    echo "Tested assertion"


proc test_cp() =
  dist_dir.remove_dir
  dist_dir.create_dir

  let dest_nim = dist_dir/"file"
  cp("test_misc.nim", dest_nim)
  do_assert dest_nim.exists_file

  dist_dir.remove_dir
  let dest_dir = dist_dir/"temp"/"dot_walk_dir_rec2"
  cp("dot_walk_dir_rec", dest_dir)
  do_assert exists_file(dest_dir/"this_also")


proc test_shell() =
  dist_dir.create_dir
  when defined(macosx): test_shell "rm -R", dist_dir


proc test() =
  test_not_nil()
  test_dot_walk_dir_rec()
  test_exceptions()
  test_safe_object()
  test_safe_string()
  test_safe_seq()
  test_cp()
  test_shell()
  echo "All tests run"


task default_task, "Runs tests by default": test()
when isMainModule: test()
