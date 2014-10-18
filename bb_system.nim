## `Badger bits <https://github.com/gradha/badger_bits>`_ system helpers.
##
## Contains stuff which I would like to see in `system
## <http://nimrod-lang.org/system.html>`_ or is common to my code for some
## reason.

import typetraits


proc last*(s: string): char {.inline.} =
  ## Returns the last entry from `s`.
  ##
  ## If `s` is nil or has zero length the zero character will be returned.
  ##
  ## Use instead of ``a[high(a)]``.
  if s.is_nil or s.len < 1:
    result = '\0'
  else:
    result = s[high(s)]


template last*[T](a: openarray[T]): T =
  ## Returns the last entry from an array like type `a`.
  ##
  ## Use instead of ``a[high(a)]``.
  a[high(a)]


template not_nil*[T](x: T): bool =
  ## Negated version of ``system.isNil()``.
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


template `?.`*[T](n: T, c: expr): T =
  ## Safe object field accessor.
  ##
  ## This operator can be used to chain field accesses which can be handy when
  ## traversing nullable relationships. See http://forum.nimrod-lang.org/t/385
  ## for a discussion of this.
  let m = n
  if m.is_nil: nil else: m.c


proc nil_echo*(s: string): string =
  ## Returns the value of `s` or the string ``(nil)`` if `s` is not nil.
  ##
  ## Mainly used for debugging like implementations of `$` procs which need to
  ## output fields of an object where the empty string provided by `safe
  ## <#safe,string>`_ might not be desirable.
  if s.is_nil: result = "(nil)"
  else: result = s


proc safe*(s: string): string =
  ## Returns a default safe value for any string if it is nil.
  ##
  ## Mostly for convenience debugging and assertions, this proc will never
  ## return nil but a default empty string. If the empty string is not good for
  ## nil you could use `nil_echo <#nil_echo>`_. Usage example:
  ##
  ## .. code-block::
  ##   proc doStuff(s: string) =
  ##     assert s.safe.len > 0, "You need to pass a non empty string!"
  ##   ...
  ##   doStuff(nil)
  let
    m = s
    default {.global.} = ""
  if m.is_nil:
    result = default
  else:
    result = m


proc safe*[T](s: seq[T]): seq[T] =
  ## Returns a default safe value for any sequence if it is nil.
  ##
  ## Mostly for convenience debugging and assertions, this proc will never
  ## return nil but a default empty sequence. Example:
  ##
  ## .. code-block::
  ##   proc doStuff(s: seq[string]) =
  ##     assert s.safe.len > 0, "You need to pass a non empty sequence!"
  ##   ...
  ##   doStuff(nil)
  let
    m = s
    default {.global.} : seq[T] = @[]
  if m.is_nil:
    result = default
  else:
    result = m


proc `$`*[T](some:typedesc[T]): string =
  ## Quick wrapper around ``typetraits.name()``.
  ##
  ## This allows `echoing types for debugging
  ## <http://forum.nimrod-lang.org/t/430>`_.
  name(T)


template elet*(t: typedesc): stmt =
  ## Captures the current exception into a typed variable.
  ##
  ## The ``elet`` template injects the variable `e` with the type `ref t`. The
  ## injected `e` variable is guaranteed to be not nil. If the type `t` is not
  ## valid, the exception EInvalidObjectConversion will be raised. Usage
  ## example:
  ##
  ## .. code-block::
  ##   try:
  ##     badIO()
  ##   except EIO:
  ##     elet EIO
  ##     echo "Got bad IO: ", e.msg

  let e {.inject.}: ref t = (ref t)getCurrentException()
  doAssert(not e.isNil, "getCurrentException() called out of except block!")


template evar*(x: expr, t: typedesc): stmt =
  ## Attempts to capture the current exception into a typed variable.
  ##
  ## The ``evar`` template injects the specified variable name `x` with the
  ## type `ref t`. The injected variable may be nil if there is no current
  ## exception or the type is incorrect. You can use this as a special case
  ## inside generic ``except`` branches. Example:
  ##
  ## .. code-block::
  ##   try:
  ##     badMath()
  ##   except:
  ##     evar m, EArithmetic
  ##     evar i, EIO
  ##     echo "auto: Is arithmetic? ", (not m.isNil)
  ##     echo "auto: Is IO? ", (not i.isNil)
  var x: ref t = nil
  try: x = (ref t)getCurrentException()
  except EInvalidObjectConversion: discard


template rassert*(cond: bool, msg: string, body: stmt) {.immediate.} =
  ## Mix between assertion in debug mode and normal ``if`` at runtime.
  ##
  ## This **runtime** assert will stop execution in debug builds through a
  ## normal assert if `cond` is not met. In release builds `body` will be run
  ## instead, which can usually contain a return to avoid crashing further down
  ## the road. Usage example:
  ##
  ## .. code-block:: nimrod
  ##   const msg = "filename parameter can't be nil!"
  ##   rassert filename.not_nil, msg:
  ##     raise new_exception(EInvalidValue, msg)
  ##   ...
  when defined(release):
    if not(cond):
      body
  else:
    assert(cond, msg)
