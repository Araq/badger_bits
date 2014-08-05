import bb_system, bb_os, sequtils, algorithm


proc test_not_nil() =
  var s: string
  assert s.is_nil
  s = ""
  assert(not s.is_nil)
  assert s.not_nil
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
  assert l == @good_result
  assert l != @bad_result
  l = to_seq(dir.walk_dir_rec)
  l.sort(system.cmp)
  assert l == @bad_result
  assert l != @good_result


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
    assert m.not_nil
    assert i.is_nil

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

proc test() =
  test_not_nil()
  test_dot_walk_dir_rec()
  test_exceptions()
  echo "All tests run"


when isMainModule: test()
