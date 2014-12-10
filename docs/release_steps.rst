=========================
Badger bits release steps
=========================

These are the steps to be performed for new stable releases of the `badger bits
module <https://github.com/gradha/badger_bits>`_. See the `README
<../README.rst>`_.

* Run ``nake test`` to verify at least basic stuff works.
* Create new milestone with version number (``vXXX``) at
  https://github.com/gradha/badger_bits/milestones.
* Create new dummy issue `Release versionname` and assign to that milestone.
* Annotate the release issue with the Nimrod commit used to compile sources or
  stable version.
* ``git flow release start versionname`` (versionname without v).
* Update version numbers:

  * Modify `README.rst <../README.rst>`_.
  * Modify `docs/changes.rst <changes.rst>`_ with list of changes and
    version/number.
  * Modify `badger_bits.nimble <../badger_bits.nimble>`_.
  * Modify `bb_system.nim <../bb_system.nim>`_.

* ``git commit -av`` into the release branch the version number changes.
* ``git flow release finish versionname`` (the tagname is versionname without
  ``v``). When specifying the tag message, copy and paste a text version of the
  changes log into the message. Add ``*`` item markers.
* Move closed issues to the release milestone.
* Increase version numbers, ``master`` branch gets +0.0.1:

  * Modify `README.rst <../README.rst>`_.
  * Modify `badger_bits.nimble <../badger_bits.nimble>`_.
  * Modify `bb_system.nim <../bb_system.nim>`_.
  * Add to `docs/changes.rst <changes.rst>`_ development version with unknown
    date.

* ``git commit -av`` into ``master`` with *Bumps version numbers for
  development version. Refs #release issue*.

* Regenerate static website.

  * Make sure git doesn't show changes, then run ``nake web`` and review.
  * ``git add gh_docs && git commit``. Tag with
    `Regenerates website. Refs #release_issue`.
  * ``./nakefile postweb`` to return to the previous branch. This also updates
    submodules, so it is easier.

* ``git push origin master stable gh-pages --tags``.
* Close the dummy release issue.
* Close the milestone on github.
* Announce at http://forum.nimrod-lang.org/.
