;;; turtle-mode.el --- Major mode for editing Turtle files

;; Copyright (C) 2020 David Robillard <d@drobilla.net>

;; Permission to use, copy, modify, and/or distribute this software for any
;; purpose with or without fee is hereby granted, provided that the above
;; copyright notice and this permission notice appear in all copies.
;;
;; THIS SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
;; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
;; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
;; ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
;; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
;; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
;; OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

;;; Commentary:

;; This mode supports rudimentary syntax highlighting and indentation for
;; Turtle.  It does not perfectly match the RDF 1.1 Turtle grammar, but does a
;; reasonably good job on typical files.
;;
;; The long string handling is a bit hacky and may take a while to actually
;; highlight when scrolling over very long strings, but it does at least end up
;; properly highlighting the string (unlike other Turtle modes out there at the
;; time of this writing).


(defun turtle-font-lock-extend-region ()
  "Extend the search region to include the surrounding long string literal."
  (eval-when-compile (defvar font-lock-beg) (defvar font-lock-end))
  (save-excursion
    (goto-char font-lock-beg)
    (let ((found (or (re-search-backward "\\\"\\\"\\\"" nil t) (point-min))))
      (goto-char font-lock-end)
      (when (re-search-forward "\\\"\\\"\\\"" nil t)
        (beginning-of-line)
        (setq font-lock-end (point)))
      (setq font-lock-beg found))))


(defconst turtle-font-lock-keywords
  '(
    ;; Prefix directives
    ("\\(@prefix\\)\\s-\\([a-zA-Z][a-zA-Z0-9\-_]*:\\)"
     (1 'font-lock-keyword-face)
     (2 'font-lock-preprocessor-face))

    ;; Base URI directive
    ("\\(@base\\)\\>"
     (1 'font-lock-keyword-face))

    ;; Single line strings
    ("\\(\\\".*\\\"\\)"
     (1 font-lock-string-face t))

    ;; Multi line strings
    ("\\(\\\"\\\"\\\"\\(.\\|\n\\)*?\\\"\\\"\\\"\\)"
     (1 font-lock-string-face t))

    ;; URI literal datatypes
    ("\\\"\\(\\^\\^<\\)\\(.*\\)\\(>\\)"
     (1 'font-lock-keyword-face)
     (2 'font-lock-type-face)
     (3 'font-lock-keyword-face))

    ;; Prefixed name literal datatypes
    ("\\\"\\(\\^\\^\\)\\([a-zA-Z][a-zA-Z0-9\-_]*:\\)\\([a-zA-Z][a-zA-Z0-9\-_]*\\)"
     (1 'font-lock-keyword-face)
     (2 'font-lock-preprocessor-face)
     (3 'font-lock-type-face))

    ;; URIs
    ("\\(<\\)\\([^>]*\\)\\(>\\)"
     (1 'font-lock-keyword-face)
     (2 'font-lock-constant-face)
     (3 'font-lock-keyword-face))

    ;; Blank nodes
    ("\\(_:[a-zA-Z][a-zA-Z0-9\-_]*\\)" 1 font-lock-variable-name-face t)

    ;; Prefixed names
    ("\\s-\\([a-zA-Z][a-zA-Z0-9\-_]*:\\)\\([a-zA-Z][a-zA-Z0-9\-_]*\\)"
     (1 'font-lock-preprocessor-face)
     (2 'font-lock-variable-name-face))

    ;; Special grammar tokens
    ("\\(\\s-\\a\\s-\\)" (1 'font-lock-keyword-face))
    ("\\(\\s-\\[\\s-\\)" (1 'font-lock-keyword-face))
    ("\\(\\s-\\]\\s-\\)" (1 'font-lock-keyword-face))
    ("\\(\\s-\\,\\s-\\)" (1 'font-lock-keyword-face))
    ("\\(\\s-\\;\\s-\\)" (1 'font-lock-keyword-face))
    ("\\(\\s-\\\.\\s-\\)" (1 'font-lock-keyword-face))
    )

  "Font lock keywords for Turtle syntax")


(defun turtle-indentation-level ()
  "Calculate the indentation level for the current line of Turtle"
  (cond ((looking-at ".*\\]\\s-*[,;]?$")
         ;; End of an anonymous node, decrease indentation
         (- (current-indentation) tab-width))

        ((looking-at ".*\\]\\s-*,\\s-*\\[$")
         ;; End of an anonymous node and the start of another, "undo" indentation
         (- (current-indentation) tab-width))

        (t
         ;; Otherwise, look at the previous line
         (save-excursion
           (forward-line -1)
           (let ((indentation (current-indentation)))
             (cond ((bobp)
                    ;; Beginning of buffer, no indentation
                    0)

                   ((or (looking-at "^<.*>$")
                        (looking-at "^[a-zA-Z]?[a-zA-Z0-9\-_]*:[a-zA-Z][a-zA-Z0-9\-_]*$"))
                    ;; Start of a resource description, increase indentation
                    (+ indentation tab-width))

                   ((looking-at ".*\\.$")
                    ;; End of a resource description or directive, no indentation
                    0)

                   ((looking-at ".*;$")
                    ;; Continuation of properties
                    (forward-line -1)
                    (if (looking-at ".*,$")
                        (- indentation tab-width) ; Outdent earlier comma
                      indentation))

                   ((looking-at ".*,$")
                    ;; Continuation of property values
                    (forward-line -1)
                    (if (looking-at ".*,$")
                        indentation ; Not the first, stay at this level
                      (+ indentation tab-width))) ; First comma, indent

                   ((looking-at ".*\\[$")
                    ;; Start of an anonymous node, increase indentation
                    (+ indentation tab-width))

                   (t
                    ;; Otherwise, use the same indentation
                    indentation)))))))


(defun turtle-indent-line ()
  "Indent current line as Turtle."
  (interactive)
  (beginning-of-line)
  (indent-line-to (max 0 (turtle-indentation-level))))


;;;###autoload
(define-derived-mode turtle-mode fundamental-mode "Turtle"
  "Major mode for editing Turtle."

  ;; Set Turtle-specific indentation function
  (set (make-local-variable 'indent-line-function) 'turtle-indent-line)

  ;; Enable multiline syntax highlighting for long strings
  (set (make-local-variable 'font-lock-multiline) t)
  (add-hook 'font-lock-extend-region-functions
            'turtle-font-lock-extend-region)

  ;; Set font lock keywords
  (set (make-local-variable 'font-lock-defaults) '(turtle-font-lock-keywords t)))

(provide 'turtle-mode)
