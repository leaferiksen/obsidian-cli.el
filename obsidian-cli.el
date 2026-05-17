;;; obsidian-cli.el --- Obsidian CLI interface -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Leaf Eriksen

;; Author: Leaf Eriksen <leaferiksen@gmail.com>
;; Keywords: convenience, tools
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

;; Obsidian must be running for the cli to work, so ensure it starts
;; on login. To automatically hide Obsidian once it launches, you can
;; use the "Javascript Init" plugin to run "electronWindow.minimize()"

;; If you want Obsidian to replicate the `obsidian-cli-update-title'
;; function, I found that the plugin "File Title Updater" did the
;; trick, once I set the "Default title source" set to "First Heading"
;; and "Sync mode" to "Filename + Heading"

;;; Code:

(require 'subr-x)

(defgroup obsidian-cli nil
  "Obsidian CLI interface."
  :prefix "obsidian-cli-"
  :group 'external)

(defvar-keymap obsidian-cli-mode-map
  :parent text-mode-map
  :doc "Local keymap for `obsidian-cli-mode'.")

(defcustom obsidian-cli-vault
  (file-name-as-directory (string-trim (shell-command-to-string "obsidian vault info=path")))
  "Path to the Obsidian vault directory. Refreshes every time
obsidian-cli.el is loaded"
  :type 'directory
  :group 'obsidian-cli)

(defun obsidian-cli-update-title ()
  "If a level one heading is found, automatically rename the file to match,
repair any [[wikilinks]] to the file, and jump the user to the new file"
  (when-let* ((path (buffer-file-name))
              (_    (string-prefix-p obsidian-cli-vault path))
              (new  (save-excursion
                      (goto-char (point-min))
                      (when (re-search-forward "^# \\(.+\\)$" nil t)
                        (match-string 1))))
              (_    (not (string= (file-name-base path) new))))
    (shell-command (format "obsidian rename file=%s name=%s"
                           (shell-quote-argument (file-name-nondirectory path))
                           (shell-quote-argument new)))
    (set-visited-file-name (expand-file-name (concat new ".md") obsidian-cli-vault) t t)
    (set-buffer-modified-p nil)))

(defun obsidian-cli-jump-to-backlink ()
  "Jump to a backlink of the current file."
  (interactive)
  (when-let* ((path  (buffer-file-name))
              (_     (string-prefix-p obsidian-cli-vault path))
              (raw   (shell-command-to-string
                      (format "obsidian backlinks file=%s"
                              (shell-quote-argument (file-name-nondirectory path)))))
              (links (split-string (string-trim raw) "\n" t))
              (pick  (pcase links
                       (`(,only) only)
                       (_ (completing-read "Backlink: " links nil t)))))
    (find-file (expand-file-name pick obsidian-cli-vault))))

;;;###autoload

(defun obsidian-cli-daily-note ()
  "Open today's daily note."
  (interactive)
  (let* ((raw (shell-command-to-string "obsidian daily:path"))
         (path (string-trim raw)))
    (if (string= path "")
        (message "Obsidian: No daily note path returned")
      (find-file (expand-file-name path obsidian-cli-vault)))))

(define-minor-mode obsidian-cli-mode
  "Toggle Obsidian CLI integration."
  :init-value nil
  :group 'obsidian-cli
  :keymap obsidian-cli-mode-map
  :lighter " ObsCLI"
  (if obsidian-cli-mode (add-hook 'after-save-hook #'obsidian-cli-update-title nil t)
    (remove-hook 'after-save-hook #'obsidian-cli-update-title t)))

(provide 'obsidian-cli)
;;; obsidian-cli.el ends here
