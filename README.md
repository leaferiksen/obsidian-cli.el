This is my suggested installation method. I hope you find this package useful!

```elisp
(use-package obsidian-cli
  :ensure t
  :vc (:url "git@github.com:leaferiksen/obsidian-cli.el.git")
  :hook (markdown-ts-mode md-ts-mode)
  :bind
  ("C-c o" . obsidian-cli-open-note)
  ("C-c j" . obsidian-cli-open-daily-note)
  (:map obsidian-cli-mode-map ("C-c C-b" . obsidian-cli-jump-to-backlink))
  :custom (obsidian-cli-rename-on-save t))
```
