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

(defcustom obsidian-cli-rename-on-save nil
  "Whether to automatically rename the file to match the first H1 on save.
Obsidian CLI will update all [[wikilinks]] to the file at the same time."
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
The parent directory and date format are derived from the preferences set in
Obsidian, but the template cannot currently be automatically added."
  (interactive)
  (let ((vault (obsidian-cli--vault))
        (path (obsidian-cli--call "daily:path")))
    (find-file (expand-file-name path vault))))

(defun obsidian-cli-open-note ()
  "Open a note from the Obsidian vault."
  (interactive)
  (let* ((vault (obsidian-cli--vault))
         (files (split-string (obsidian-cli--call "files" "ext=md") "\n" t))
         (pick (completing-read "Open note: " files nil t)))
    (find-file (expand-file-name pick vault))))

(defun obsidian-cli-rename-file ()
  "Use Obsidian to rename file if a level one heading is found.
repair any [[wikilinks]] to the file, and jump the user to the new file"
  (when-let* (obsidian-cli-rename-on-save
              (path (buffer-file-name))
              (vault (obsidian-cli--vault))
              ((string-prefix-p vault path))
              (new
               (save-excursion
                 (goto-char (point-min))
                 (and (re-search-forward "^# \\(.+\\)$" nil t)
                      (match-string 1))))
              ((not (string= (file-name-base path) new))))
    (obsidian-cli--call
     "rename"
     (format "file=%s" (file-name-nondirectory path))
     (format "name=%s" new))
    (set-visited-file-name (expand-file-name (concat new ".md") vault) t t)
    (set-buffer-modified-p nil)))

(defun obsidian-cli-jump-to-backlink ()
  "Jump to a backlink of the current file."
  (interactive)
  (when-let* ((vault (obsidian-cli--vault))
              (path (buffer-file-name))
              ((string-prefix-p vault path))
              (raw
               (obsidian-cli--call
                "backlinks" (format "file=%s" (file-name-nondirectory path))))
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
;; fill-column: 80
;; elisp-autofmt-on-save-p: always
;; end:
