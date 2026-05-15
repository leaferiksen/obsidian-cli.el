This is my suggested installation method. I hope you find this package useful!

```elisp
(use-package obsidian-cli
  :ensure t
  :vc ( :url "https://github.com/leaferiksen/obsidian-cli.el")
  :hook md-ts-mode
  :bind
  ("C-c j" . obsidian-cli-daily-note)
  ( :map obsidian-cli-mode-map
    ("C-c C-b" . obsidian-cli-jump-to-backlink)))
```
