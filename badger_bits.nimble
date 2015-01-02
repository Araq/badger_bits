[Package]
name = "badger_bits"
version = "0.2.2"
author = "Grzegorz Adam Hankiewicz"
license = "MIT"
description = """
Tweaks and shortcuts for the Nim programming language.

Not good enough to make it to the standard library.

Not bad enough to copy and paste.
"""

installDirs = """

docs

"""

InstallFiles = """

README.rst
bb_nake.nim
bb_os.nim
bb_system.nim
license.rst
nakefile.nim

"""

[Deps]
Requires: """

nake >= 1.4

"""
