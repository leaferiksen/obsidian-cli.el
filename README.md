# Emacs Obsidian CLI

Access the power of the Obsidian CLI from within GNU Emacs!

Here is how I install it:

```elisp
(setopt use-package-vc-prefer-newest t)

(use-package obsidian-cli
  :ensure t
  :vc (:url "https://github.com/leaferiksen/obsidian-cli.el")
  :hook (markdown-ts-mode md-ts-mode)
  :bind
  ("C-c o" . obsidian-cli-open-note)
  ("C-c j" . obsidian-cli-open-daily-note)
  (:map obsidian-cli-mode-map ("C-c C-b" . obsidian-cli-jump-to-backlink))
  :custom (obsidian-cli-rename-on-save t))
```

The CLI only provides the path to the vault that is currently open. If multiple vaults are open at once, the CLI only sees the path of the first vault that was opened. If multi-vault path support is added to the CLI, please tell me about it, because I would be happy to support the feature, even though I don't need it.

Obsidian must be running for the CLI to work. If you run Obsidian at login but don't want to deal with hiding it, you can automatically hide Obsidian once it is done launching using the "Javascript Init" plugin to run `electronWindow.minimize()`.

If you want Obsidian to also rename files to match headings, I found that the plugin "File Title Updater" did the trick, once I set the "Default title source" set to "First Heading" and "Sync mode" to "Filename + Heading".

As I use both of these this plugins personally, I will try to update these guidelines as Obsidian plugins come and go. If you know of solutions that do no require plugins, and are still cross-platform, please tell me about them.
