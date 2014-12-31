==================
Badger bits readme
==================

This module contains `gradha's <https://github.com/gradha>`_ tweaks and
shortcuts for the `Nim programming language <http://nim-lang.org>`_.  You can
read pre generated documentation at http://gradha.github.io/badger_bits/.  You
can also generate this documentation locally typing ``nake doc`` once you have
the software on your machine.


Changes
=======

This is development version 0.2.1. For a list of changes see the
`docs/changes.rst <docs/changes.rst>`_ file.


License
=======

`MIT license <license.rst>`_.


Installation
============

Development version
-------------------

Install the `Nim compiler <http://nim-lang.org>`_. Then use `Nim's Nimble
package manager <https://github.com/nim-lang/nimble>`_ to install locally the
GitHub checkout::

    $ git clone https://github.com/gradha/badger_bits.git
    $ cd badger_bits
    $ nimble install -y

If you don't mind downloading the git repository every time, you can also tell
Nimble to install the latest development version directly from git::

    $ nimble install -y https://github.com/gradha/badger_bits.git@#head

Stable version
--------------

The stable version is usually meant to be used as a dependency for another
project. You would have to add the following to your nimble spec::

    [Deps]
    Requires: "https://github.com/gradha/badger_bits.git@#stable"

Alternatively you could use a specific tag::

    [Deps]
    Requires: "https://github.com/gradha/badger_bits.git@#vX.Y.Z"


Git branches
============

This project uses the `git-flow branching model
<https://github.com/nvie/gitflow>`_ with reversed defaults. Stable releases are
tracked in the ``stable`` branch. Development happens in the default ``master``
branch.


Feedback
========

You can send me feedback through `GitHub's issue tracker
<https://github.com/gradha/badger_bits/issues>`_. I also take a look from time
to time to `Nim's forums <http://forum.nim-lang.org>`_ where you can talk to
other Nim programmers.
