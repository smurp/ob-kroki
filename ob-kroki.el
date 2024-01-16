;;; ob-kroki.el --- org-babel functions for kroki evaluation

;; Copyright (C) 2009-2021  Free Software Foundation, Inc.

;; Author: Shawn Murphy
;; Keywords: literate programming, reproducible research
;; Homepage: http://orgmode.org

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-Babel support for generating images using kroki
;;
;; From http://kroki.io/
;;   "Kroki provides a unified API with support for
;;   BlockDiag (BlockDiag, SeqDiag, ActDiag, NwDiag, PacketDiag, RackDiag),
;;   BPMN, Bytefield, C4 (with PlantUML), Ditaa, Erd, Excalidraw, GraphViz,
;;   Mermaid, Nomnoml, Pikchr, PlantUML, SvgBob, UMLet, Vega, Vega-Lite, WaveDrom.
;;   ... and more to come!"
;;
;; This implementation was based on ob-dot.el
;;   https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-dot.html
;;
;; This differs from most standard languages in that
;;
;; 1) there is no such thing as a "session" in kroki
;;
;; 2) we are generally only going to return results of type "file"
;;
;; 3) we are adding the "file" and "cmdline" header arguments
;;
;; 4) there are no variables
;;
;; Installation:
;;   1) put the following in your .emacs
;;
;;     (if (file-exists-p "~/.emacs.d/ob-kroki/ob-kroki.el")
;;       (let ((load-path load-path))
;;         (add-to-list 'load-path "~/.emacs.d/ob-kroki")
;;         (require 'ob-kroki)))
;;   2) Install kroki-cli
;;    from https://docs.kroki.io/kroki/setup/kroki-cli/
;;       It enables command lines such as:
;;          kroki convert simple.er --out-file out.png


;; kroki convert --help
;; Convert text diagram to image

;; Usage:
;; kroki convert file [flags]
;;
;;   (note that "file" above can equal "-" to indicate input from STDIN)
;;
;; Flags:
;; -c, --config string     alternate config file [env KROKI_CONFIG]
;; -f, --format string     output format [base64 jpeg pdf png svg]
;;                         (default: infer from output file extension otherwise svg)
;; -h, --help              help for convert
;; -o, --out-file string   output file (default: based on path of input file); use - to output to STDOUT
;; -t, --type string       diagram type [actdiag blockdiag bpmn bytefield
;;                         c4plantuml ditaa erd excalidraw graphviz mermaid nomnoml
;;                         nwdiag packetdiag plantuml rackdiag seqdiag svgbob umlet
;;                         vega vegalite wavedrom] (default: infer from file extension)
;;
;; SOME MINIMALIST EXAMPLES OF kroki INVOCATION
;;   echo "digraph offon {on -> off -> on; }" \
;;     | kroki convert - --out-file off_on.png --type graphviz && open off_on.png
;;
;;   kroki convert beauty_truth.dot --out-file beauty_truth.png --type graphviz
;;
;;   kroki convert beauty_truth.dot --out-file beauty_truth.doh --type graphviz --format png
;;   # This demonstrates that the output format dominates the out-file extension

;;; Code:
(require 'ob)

(defvar org-babel-default-header-args:kroki
  '((:results . "file") (:exports . "results"))
  "Default arguments to use when evaluating a kroki source block.")

(defun org-babel-expand-body:kroki (body params)
  "Expand BODY according to PARAMS, return the expanded body."
  (let ((vars (org-babel--get-vars params)))
    (mapc
     (lambda (pair)
       (let ((name (symbol-name (car pair)))
	     (value (cdr pair)))
	 (setq body
	       (replace-regexp-in-string
		(concat "$" (regexp-quote name))
		(if (stringp value) value (format "%S" value))
		body
		t
		t))))
     vars)
    body))

(defun org-babel-execute:kroki (body params)
  "Execute a block of Kroki code with org-babel.
This function is called by `org-babel-execute-src-block'."
  (let* ((out-file (cdr (or (assq :file params)
			    (error "You need to specify a :file parameter"))))
	 (cmdline (or (cdr (assq :cmdline params))
		      (format "--format %s" (file-name-extension out-file))))
	 (cmd (or (cdr (assq :cmd params)) "kroki"))
	 (coding-system-for-read 'utf-8) ;use utf-8 with sub-processes
	 (coding-system-for-write 'utf-8)
	 (in-file (org-babel-temp-file "kroki-")))
    (with-temp-file in-file
      (insert (org-babel-expand-body:kroki body params)))
    (org-babel-eval
     (concat cmd
	     " convert " (org-babel-process-file-name in-file)
	     " " cmdline
	     " --out-file " (org-babel-process-file-name out-file)) "")
    nil)) ;; signal that output has already been written to file

(defun org-babel-prep-session:kroki (_session _params)
  "Return an error because Kroki does not support sessions."
  (error "Kroki does not support sessions"))

(provide 'ob-kroki)

;; Sample Invocation
;; #+BEGIN_SRC kroki :file /tmp/truth_beauty.png :cmdline --type graphviz :exports results
;;   digraph bt {
;;     rankdir="LR"
;;     truth -> beauty -> truth;
;;   }
;; #+END_SRC

;;; ob-kroki.el ends here
