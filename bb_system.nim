## `Badger bits <https://github.com/gradha/badger_bits>`_ system helpers.
##
## Contains stuff which I would like to see in `system
## <http://nimrod-lang.org/system.html>`_ or is common to my code for some
## reason.

template not_nil*[T](x: T): bool =
  ## Negated version of `system.isNil()`.
  ##
  ## `system.isNil <http://nimrod-lang.org/system.html#isNil,T>`_ is awkward to
  ## use with assertions:
  ##
  ## .. code-block:: nimrod
  ##   assert x.not_nil
  ##   # The following does not compute.
  ##   #assert not x.is_nil
  ##   # Parenthesis, parenthesis everywhere.
  ##   assert(not x.is_nil)
  (not x.isNil)
