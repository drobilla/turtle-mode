Turtle Mode
===========

This is an Emacs major mode for writing [Turtle][] files that supports basic
syntax highlighting and indentation.

In particular, it supports multi-line string literals reasonably well, unlike
similar older modes (that I am aware of, anyway).  That said, it is far from
perfect and may not support more esoteric files or various corner cases of the
grammar well.  See the comments in the source code for details and caveats.

Usage
-----

Put `turtle-mode.el` in your load path and add something like the following to
your init.el:

```elisp
(require 'turtle-mode)

(add-to-list 'auto-mode-alist '("\\.n3"  . turtle-mode))
(add-to-list 'auto-mode-alist '("\\.ttl" . turtle-mode))
```

Contributions
-------------

Always welcome.  This mode is rather hastily written and is not at all
comprehensive, but it has been written from scratch in an attempt to make
things as clear as possible and should hopefully be easy to work with.

Configuration support is one obvious area for improvement.  It could also
probably be extended to support [TriG][] relatively easily.  If someone versed
in the dark arts of font-lock could fix the laggy long-string highlighting,
that would be particularly appreciated.

 -- David Robillard <d@drobilla.net>

[Turtle]: https://www.w3.org/TR/turtle/
[TriG]: https://www.w3.org/TR/trig/
