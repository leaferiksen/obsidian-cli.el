;;; obsidian-cli.el --- Obsidian CLI interface -*- lexical-binding: t; -*-

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

;; Obsidian must be running for the cli to work, so ensure it starts
;; on login. To automatically hide Obsidian once it launches, you can
;; use the "Javascript Init" plugin to run "electronWindow.minimize()"

;; If you want Obsidian to replicate the `obsidian-cli-update-title'
;; function, I found that the plugin "File Title Updater" did the
;; trick, once I set the "Default title source" set to "First Heading"
;; and "Sync mode" to "Filename + Heading"

;;; Code:

(defun obsidian-cli--call (&rest args)
  "Call obsidian with ARGS and return the output string.
Signal an error if the command fails or returns a `not running' message."
  (with-temp-buffer
    (let ((exit-code (apply #'call-process "obsidian" nil t nil args)))
      (let ((output (string-trim (buffer-string))))
        (if (not (zerop exit-code))
            (user-error "Obsidian: %s" (if (string= output "") "Command failed" output))
          output)))))

(defun obsidian-cli--vault ()
  "Return the vault path from the CLI."
  (file-name-as-directory (obsidian-cli--call "vault" "info=path")))

(defun obsidian-cli-update-title ()
  "If a level one heading is found, automatically rename the file to match,
repair any [[wikilinks]] to the file, and jump the user to the new file"
  (when-let* ((path  (buffer-file-name))
              (vault (obsidian-cli--vault))
              (_     (string-prefix-p vault path))
              (new   (save-excursion
                       (goto-char (point-min))
                       (when (re-search-forward "^# \\(.+\\)$" nil t)
                         (match-string 1))))
              (_     (not (string= (file-name-base path) new))))
    (obsidian-cli--call "rename"
                        (format "file=%s" (file-name-nondirectory path))
                        (format "name=%s" new))
    (set-visited-file-name (expand-file-name (concat new ".md") vault) t t)
    (set-buffer-modified-p nil)))

(defun obsidian-cli-jump-to-backlink ()
  "Jump to a backlink of the current file."
  (interactive)
  (when-let* ((vault (obsidian-cli--vault))
              (path  (buffer-file-name))
              (_     (string-prefix-p vault path))
              (raw   (obsidian-cli--call "backlinks"
                                         (format "file=%s" (file-name-nondirectory path))))
              (links (split-string raw "\n" t))
              (pick  (pcase links
                       (`(,only) only)
                       (_ (completing-read "Backlink: " links nil t)))))
    (find-file (expand-file-name pick vault))))

;;;###autoload

(defun obsidian-cli-daily-note ()
  "Open today's daily note."
  (interactive)
  (let ((vault (obsidian-cli--vault))
        (path  (obsidian-cli--call "daily:path")))
    (find-file (expand-file-name path vault))))

(define-minor-mode obsidian-cli-mode
  "Toggle Obsidian CLI integration."
  :init-value nil
  :lighter " OCLI"
  :keymap (make-sparse-keymap)
  (if obsidian-cli-mode (add-hook 'after-save-hook #'obsidian-cli-update-title nil t)
    (remove-hook 'after-save-hook #'obsidian-cli-update-title t)))

(provide 'obsidian-cli)
;;; obsidian-cli.el ends here
