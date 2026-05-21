# Contributing

If you want to submit a pull request, please flatten unnecessarily nested `if/when/let` blocks using `if-let*/when-let*/and-let*`, remove single-use local variables, and avoid using cl-lib.

Also, feel free to raise the minimum supported version of the package if it would make the code of your PR any simpler! Elisp is complicated enough without supporting old versions.

`obsidian-cli` will not implement features which require information that the CLI does not provide. I am not interested in maintaining code that directly reads from potentially unstable data formats like Obsidian's preference files, as I want to ensure that the continued maintenance of this package is manageable for many years to come, so long as I remain in good health.
