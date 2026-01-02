# godere

A simple bash command to help developers navigate between projects.

## Usage:

```bash
# Jump to /dev/projects/php/softdrink
gd softdrink

# But also works with
gd sdr # fuzzy match
gd php # most recent PHP project

# Or just enter
gd
# to jump to the most recently modified project
```

The target directory is determined by:

- Direct or partial match of the directory name
- Fuzzy pattern match (prj -> project)
- Existence of .git repository
- Date of last change

Godere just picks the most likely match and `cd`-s there. It's that simple.

**TIP:** Set env. variable `GD_DEBUG` to 1 to see debugging output.

## Installation

Paste this into your terminal and follow the on-screen instructions:

```
wget -O- -q https://raw.githubusercontent.com/panta82/godere/master/install.sh | bash
```

Alternatively, if you're a jaded untrusting soul, you could clone the repository, inspect the content and _then_ run `install.sh`,

## Requirements

- #### Bash 4.3

  It might work on older versions, but it wasn't tested and installer won't support it.

- #### GNU toolchain

  No worries on Linux.
  On Mac, please install [homebrew](http://brew.sh/), then execute `brew install coreutils`.

- #### Screen compatible command
  Either `screen` or `whiplash`. Should come preinstalled on linux. `brew install screen` on Mac.

## Version history

| Version | Description                                                                                                                     |
| ------- | ------------------------------------------------------------------------------------------------------------------------------- |
| 0.1     | Initial release                                                                                                                 |
| 0.2     | Better fuzzy parsing when used with multiple arguments. Eg. `gd word1 word2`                                                    |
| 0.3     | Better installer safety. Added Mac support                                                                                      |
| 0.4     | Speed up by excluding directories like `.git` and `node_modules`. Also fix installer bash version detection (now works with 5). |

## Licence

MIT
