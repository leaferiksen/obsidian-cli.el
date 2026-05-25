;;; obsidian-cli.el --- Obsidian CLI interface -*- lexical-binding: t -*-

;; Copyright (C) 2026  Leaf Eriksen

;; Author: Leaf Eriksen <leaferiksen@gmail.com>
;; Keywords: convenience, tools
;; Package-Requires: ((emacs "30.1"))
;; URL: https://github.com/leaferiksen/obsidian-cli.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Obsidian CLI is an Emacs Lisp package which allows you to access the
;; superpowers of Obsidian via the app's included CLI.

;;; Code:

(defgroup obsidian-cli nil
  "Obsidian CLI interface."
  :group 'external
  :prefix "obsidian-cli-")

(defcustom obsidian-cli-note-extensions '("md")
  "List of file extensions to show in the note selection menu."
  :type '(repeat string)
  :group 'obsidian-cli)

(defcustom obsidian-cli-rename-on-save nil
  "Non-nil means run `obsidian-cli-rename-file' after saving files."
  :type 'boolean
  :group 'obsidian-cli)

(defun obsidian-cli--call (&rest args)
  "Call obsidian with ARGS and return the output string.
Signal an error if the command fails or returns a `not running' message."
  (with-temp-buffer
    (let* ((exit-code (apply #'call-process "obsidian" nil t nil args))
           (output (string-trim (buffer-string))))
      (if (zerop exit-code)
          output
        (user-error "Obsidian: %s"
                    (if (string= output "")
                        "Command failed"
                      output))))))

(defun obsidian-cli--vault ()
  "Return the vault path from the CLI."
  (file-name-as-directory (obsidian-cli--call "vault" "info=path")))

(defun obsidian-cli-open-daily-note ()
  "Open today's daily note.
The parent directory and date format are derived from the preferences
set in Obsidian, but the template cannot currently be automatically
added."
  (interactive)
  (let ((vault (obsidian-cli--vault))
        (path (obsidian-cli--call "daily:path")))
    (find-file (expand-file-name path vault))))

(defun obsidian-cli-open-note ()
  "Open a file from the Obsidian vault.
The list of included file types is `obsidian-cli-note-extensions'"
  (interactive)
  (let* ((vault (obsidian-cli--vault))
         (files
          (let (acc)
            (dolist (ext obsidian-cli-note-extensions)
              (setq acc (nconc acc (split-string (obsidian-cli--call "files" (format "ext=%s" ext)) "\n" t))))
            acc))
         (pick (completing-read "Open note: " files nil t)))
    (find-file (expand-file-name pick vault))))

(defun obsidian-cli-rename-file ()
  "Rename a .md file in the vault, if a level one heading is found.
Additionally, repair any [[wikilinks]] to the file, and navigate the
user to the new file"
  (when-let* (obsidian-cli-rename-on-save
              (path (buffer-file-name))
              ((string-suffix-p ".md" path))
              (vault (obsidian-cli--vault))
              ((string-prefix-p vault path))
              (new
               (save-excursion
                 (goto-char (point-min))
                 (and (re-search-forward "^# \\(.+\\)$" nil t) (match-string 1))))
              ((not (string= (file-name-base path) new))))
    (obsidian-cli--call "rename" (format "file=%s" (file-name-nondirectory path)) (format "name=%s" new))
    (set-visited-file-name (expand-file-name (concat new ".md") vault) t t)
    (set-buffer-modified-p nil)))

(defun obsidian-cli-jump-to-backlink ()
  "Jump to a backlink of the current file."
  (interactive)
  (when-let* ((vault (obsidian-cli--vault))
              (path (buffer-file-name))
              ((string-prefix-p vault path))
              (raw (obsidian-cli--call "backlinks" (format "file=%s" (file-name-nondirectory path))))
              (links (split-string raw "\n" t))
              (pick
               (pcase links
                 (`(,only) only)
                 (_ (completing-read "Backlink: " links nil t)))))
    (find-file (expand-file-name pick vault))))

;;;###autoload

(define-minor-mode obsidian-cli-mode
  "Toggle Obsidian CLI integration."
  :init-value nil
  :lighter " OCLI"
  :group 'obsidian-cli
  :keymap
  (make-sparse-keymap)
  (if obsidian-cli-mode
      (add-hook 'after-save-hook #'obsidian-cli-rename-file nil t)
    (remove-hook 'after-save-hook #'obsidian-cli-rename-file t)))

(provide 'obsidian-cli)
;;; obsidian-cli.el ends here

;; Local variables:
;; fill-column: 1000
;; elisp-autofmt-on-save-p: always
;; end:
