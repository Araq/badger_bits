import bb_system

proc test() =
  ## Micro test for this module.
  var s: string
  assert s.is_nil
  s = ""
  assert(not s.is_nil)
  assert s.not_nil
  s = nil

  echo "All tests run"

when isMainModule: test()
