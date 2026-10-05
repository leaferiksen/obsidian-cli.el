# Emacs Obsidian CLI

Access the power of the Obsidian CLI from within GNU Emacs!

```elisp
(setopt use-package-vc-prefer-newest t)
```
`package-vc-install` `https://github.com/leaferiksen/obsidian-cli.el`

optional goodies:

```elisp
(add-hook 'markdown-ts-mode-hook #'obsidian-cli-mode)
;; Synchronize file names with titles.
(setopt obsidian-cli-rename-on-save t)
;; File types you want to search for
(setopt obsidian-cli-note-extensions '("md" "tsv"))
;; Change the global key prefix
(setopt obsidian-cli-global-prefix "C-c N")
;; Or disable global keybindings entirely
(setopt obsidian-cli-global-prefix nil)
```

The CLI only provides the path to the vault that is currently open. If multiple vaults are open at once, the CLI only sees the path of the first vault that was opened. If multi-vault path support is added to the CLI, please tell me about it, because I would be happy to support the feature, even though I don't need it.

Obsidian must be running for the CLI to work. If you run Obsidian at login but don't want to deal with hiding it, you can automatically hide Obsidian once it is done launching using the "Javascript Init" plugin to run `electronWindow.minimize()`.

If you want Obsidian to also rename files to match headings, I found that the plugin "File Title Updater" did the trick, once I set the "Default title source" set to "First Heading" and "Sync mode" to "Filename + Heading".

As I use both of these this plugins personally, I will try to update these guidelines as Obsidian plugins come and go. If you know of solutions that do no require plugins, and are still cross-platform, please tell me about them.
