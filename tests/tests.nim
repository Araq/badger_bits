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


proc test() =
  test_not_nil()
  test_dot_walk_dir_rec()
  echo "All tests run"


when isMainModule: test()
