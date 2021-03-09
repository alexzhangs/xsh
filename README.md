[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors)

[![GitHub tag](https://img.shields.io/github/tag/alexzhangs/xsh.svg?style=flat-square)](https://github.com/alexzhangs/xsh/)
[![GitHub](https://img.shields.io/github/license/alexzhangs/xsh.svg?style=flat-square)](https://github.com/alexzhangs/xsh/)
[![GitHub last commit](https://img.shields.io/github/last-commit/alexzhangs/xsh.svg?style=flat-square)](https://github.com/alexzhangs/xsh/)

[![Travis (.com)](https://img.shields.io/travis/com/alexzhangs/xsh.svg?style=flat-square)](https://travis-ci.com/alexzhangs/xsh)
[![GitHub issues](https://img.shields.io/github/issues/alexzhangs/xsh.svg?style=flat-square)](https://github.com/alexzhangs/xsh/)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/alexzhangs/xsh.svg?style=flat-square)](https://github.com/alexzhangs/xsh/)

# e<span style="color:red">X</span>tension of ba<span style="color:red">SH</span>

xsh is an e<span style="color:red">__x__</span>tension of ba<span style="color:red">__sh__</span>. It works as a bash library framework.

xsh aimed to provide a uniform and easy way to reuse bash code, like what a library does.

xsh - this repository, in a narrow sense, is not a library itself. It's just a framework, in a broad sense xsh along with other repositories, such as `xsh-lib/core` as a whole, is a bash library with a framework.

Why started this?
It is the only way I can write nice shellcode for many different purposes so quickly, in the meanwhile, keep them well-organized as they grow, and be able to reuse them at the time they are needed again.

![xsh usage](doc/xsh-usage.png)


## 1. Requirements

Tested with bash:

* 4.3.48 on Linux
* 3.2.57 on macOS

This project is still at version `0.x`, and should be considered immature.



## 2. Design Philosophy

* Reuse the shellcode previously written, provide a uniform way to organize the code, document the code, format the code, execute the code, even the way you write the code. As a result, some well-organized bash code libraries will be born.

* Easy to bootstrap(install).

  The only thing you need is a bash and Git client.

  ```bash
  $ git clone https://github.com/alexzhangs/xsh
  $ bash xsh/install.sh
  $ . ~/.xshrc
  ```

* Easy to invoke.

  E.g. Call a utility named `upper` under the package `string` in the library `x` :

  ```bash
  $ xsh x/string/upper 'hello world'

  HELLO WORLD
  ```

* Easy to understand how it works.

  __xsh framework__, in technical, is just a single function, called `xsh()`, the only function inside `xsh.sh`.

  Through `xsh()`, it's able to load/unload libraries, call utilities of libraries, and get help.

  __xsh libraries__, are some Git repositories, hosted online, contain some `.sh` files, called utilities, present as functions and scripts, organized with some simple rules.

  You can build your libraries with your Git repositories.

* Easy to make your existing code a library.

  An xsh library is just a Git repo following some simple rules. The rules will be talked about later in the development section. Any repos following that rules can be able to load as xsh libraries.



### 2.1. What does xsh Framework Do?

* Provide an easy way to document and represent help and usage info
* Support basic logging
* Support debugging
* Support library versioning
* Handle the load/unload/update of libraries



### 2.2. What do xsh Libraries Do?

* Provide a container for utilities
* Provide rules for organizing utilities by packages

The xsh framework supports both public and private libraries.



### 2.3 What do xsh Utilities Do?

* Provide the fundamental function
* Provide help and usage information
* Handle temporary files
* Handle logs
* Handle output

Of course, some of the above topics can be built as libraries, packages, or utilities themself.



## 3. xsh Bootstrap/Installation

The only thing you need is a bash and Git client.

```bash
$ git clone https://github.com/alexzhangs/xsh
$ bash xsh/install.sh
$ . ~/.xshrc
```



## 4. xsh Usage

Before you can do something useful with xsh, you must load some libraries.



### 4.1. Load xsh Libraries

Use the `xsh load` command to load a library.

Loading the latest tagged version of the library [xsh-lib/core](https://github.com/xsh-lib/core), you should issue:

```bash
$ xsh load xsh-lib/core

Cloning into '/Users/alex/.xsh/repo/xsh-lib/core'...
remote: Enumerating objects: 401, done.
remote: Counting objects: 100% (401/401), done.
remote: Compressing objects: 100% (237/237), done.
remote: Total 1276 (delta 149), reused 367 (delta 133), pack-reused 875
Receiving objects: 100% (1276/1276), 165.74 KiB | 18.00 KiB/s, done.
Resolving deltas: 100% (516/516), done.
Deleted tag '0.1.0' (was 5e7dcfb)
From https://github.com/xsh-lib/core
 * [new tag]         0.1.0      -> 0.1.0
__xsh_git_force_update: INFO: Already at the latest version: 0.1.0.
```

Loading the latest development state of the library [xsh-lib/core](https://github.com/xsh-lib/core) on default branch `master`, you should issue:

```bash
$ xsh load -b master xsh-lib/core
```

After the lib is loaded, you can use the `xsh list` command to list all loaded libraries.

```bash
$ xsh list

x (0.1.0) => xsh-lib/core
```

To list all the utilities of the library `x`, use:

```bash
$ xsh list x

[SCRIPT] x/log/filter
[FUNCTIONS] x/string/lower
[FUNCTIONS] x/string/random
[FUNCTIONS] x/string/upper
[FUNCTIONS] x/string/uuid
...
```



#### 4.1.1. Update the Loaded xsh Libraries

Use the `xsh update` command to update loaded libraries.

To update the previously loaded library `xsh-lib/core`, simply issue:

```
$ xsh update xsh-lib/core

Deleted tag '0.1.0' (was 5e7dcfb)
From https://github.com/xsh-lib/core
 * [new tag]         0.1.0      -> 0.1.0
__xsh_git_force_update: INFO: Already at the latest version: 0.1.0.
```



#### 4.1.2. Unload the loaded xsh Libraries

Use the `xsh unload` command to unload loaded libraries.

To unload the previously loaded library `xsh-lib/core`, simply issue:

```bash
$ xsh unload xsh-lib/core
```



### 4.2. Invoke xsh Utilities

There are three methods to invoke xsh utilities.

Before to talk about that, let's get familiar with the glossary `LPUE`, `LPUR`, and `LPUC`.

* LPUE stands for `Lib/Package/Util Expression`,  a LPUE example for the library `xsh-lib/core` is `x/string/upper`.

* LPUR stands for `Lib/Package/Util Regex`,  a LPUR example for the library `xsh-lib/core` is `x/string` that matches all the utilities under the package string.

* LPUC stands for `Lib/Package/Util Callable`, a LPUC example for the library `xsh-lib/core` is `x-string-upper`.

Now let's get back to the three methods:

1. Call an individual LPUE.

   The syntax:

   ```bash
   $ xsh <LPUE> [options]
   ```

   A sample:

   ```bash
   $ xsh x/string/upper 'hello world'

   HELLO WORLD
   ```

2. Call LPUEs in batch. You can't pass any options.

   The syntax:

   ```bash
   $ xsh calls <LPUE> ...
   ```

   A sample:

   ```bash
   $ xsh calls x/string/random x/string/uuid

   e30e865ed22f3ef94be36c77-e507-4eee-9075-1aa259c1613e
   ```

3. Call a LPUC without the leading `xsh` command.

   The syntax:

   ```bash
   <LPUC> [options]
   ```

   In order to call a LPUC directly, you must import the LPUE first.

   Use command `xsh imports` to import LPUEs. Afterward, you can call them directly as the syntax: `<lib>-<package>-<util>`.

   A sample:

   ```bash
   $ xsh imports x/string

   $ x-string-upper 'hello world'
   HELLO WORLD

   $ x-string-uuid
   4be36c77-e507-4eee-9075-1aa259c1613e
   ```



### 4.3. Update xsh itself

See the current xsh version:

```bash
$ xsh version

0.1.4
```

List all available xsh versions(tags):

```bash
$ xsh versions

0.1.0
0.1.1
0.1.2
0.1.3
0.1.4
```

Update xsh to the latest tagged version:

```bash
$ xsh upgrade
```

Update xsh to a historical tagged version:

```bash
$ xsh upgrade -t <tag>
```



### 4.4. Get Help

See the help info of xsh itself:

```bash
$ xsh help
```

See the help info of xsh utilities by LPUR:

```bash
$ xsh help <LPUR>
```

See the specific section of help info of xsh utilities by LPUR:

```bash
$ xsh help -s <SECTION> <LPUR>
```

See the code of xsh utilities by LPUR:

```bash
$ xsh help -c <LPUR>
```

List all loaded libraries:

```bash
$ xsh list

x (0.1.0) => xsh-lib/core
```

List utilities by LPUR:

```bash
$ xsh list <LPUR>
```

List all utilities of all libraries:

```
$ xsh list '*'
```



## 5. Development



### 5.1. How to Make Your Own xsh Libraries?

The directory structure and files of a sample library look like this:

```
xsh-lib-sample/
├── functions
│   └── string
│       └── lower.sh
│       └── random.sh
│       └── upper.sh
│       └── uuid.sh
├── scripts
│   └── log
│       └── filter.sh
└── xsh.lib
```

Let each of your functions be a single `.sh` file, named as the same as the function name, put them under the directory `functions`, you are free to organize the subdirectories, for this sample, they are `string` and `log` that is called `packages`.



#### 5.1.1. xsh.lib

`xsh.lib` is a config file for the library, `xsh` will read configuration from it.

Supported configurations:

##### name=<lib_name>
* Required: YES

* Description: <lib_name> is used as library name.



#### 5.1.2 Sample code

cat `xsh-lib-sample/xsh.lib`:

```
name=smpl
```

cat `xsh-lib-sample/functions/string/upper.sh`:

```bash
#? Usage:
#?   @upper STRING ...
#?
#? Output:
#?   Uppercase presentation of STRING.
#?
#? Example:
#?   @upper Foo
#?   # FOO
#?
function upper () {
    echo "$@" | tr [a-z] [A-Z]
}
```

You will need to follow the comment style to let xsh generate help info.

The function should be started with the exact syntax:

```
function <name> ()
```

It's pretty the same with script files, except that you don't have to define functions inside the script.



#### 5.1.3. Commit the code and test it

Push the code to a Git repo, for example, Github, on branch `master`, then the library is ready for the test.

Load the sample library `xsh-lib-sample` on Github:

Note: Option `-b master` is necessary to tell you are loading the latest untagged version for testing purposes.

```bash
$ xsh load -b master <yourusername>/xsh-lib-sample
```

Or if the Git repo isn't on Github, issue:

```
$ xsh load -s http://yourgitserver.com -b master <yourusername>/xsh-lib-sample
```

Then can be called as:

```bash
$ xsh smpl/string/lower
$ xsh smpl/string/upper
$ xsh smpl/log/filter
```



#### 5.1.4. Publish the library

To tell the world that the library is ready, you have to make at least one Git tag to publish the library.

To use [Semantic Versioning](https://semver.org) for the tag name is recommended.

To make an annotated tag `1.0.0` on the latest commit of branch `master`, issue:

```
$ git tag -a -m 'v1.0.0' 1.0.0
```

Then the library is ready.

Load the published sample library `xsh-lib-sample` on Github:

```bash
$ xsh load <yourusername>/xsh-lib-sample
```



### 5.2. Debugging (Debug Mode)

With the debug mode enabled, the shell options: `-vx` is set for the debugging utilities. Debug mode is available only for the commands started with `xsh`. 

Enable debug mode by setting an environment variable: `XSH_DEBUG`.

Values for XSH_DEBUG:
```
1: Debugging current called xsh utility.
<LPUR>: Debugging the matching xsh utilities.
```
Example:

Enable `set -vx` for the utility `/string/upper`:
```bash
$ XSH_DEBUG=1 xsh /string/upper foo
```

Enable `set -vx` for all utilities under the package `/string`:
```bash
$ XSH_DEBUG='/string' xsh /string/upper foo
```

The above is for debugging xsh libraries.
For the general debugging purpose, see `xsh help debug`. 

`xsh debug <FUNCTION | SCRIPT>`

It provides a consistent way to debug functions and scripts without having to manually switch the shell options on and off, especially with functions, the syntax `bash -x script.sh` is out of hands. Although you may use the subprocess syntax `(set -x; foo_func)` to avoid messing the current process up, but subprocess has its own side effection.



### 5.3 Development at Local (Dev Mode)

The dev mode is for developers to develop xsh libraries.
With the dev mode enabled, the utilities from the development library will be called rather than those from the normal library.

Before using the dev mode, you need to create symbol links for the libraries that need to use dev mode, put the symbol links in the directory `~/.xsh/lib-dev`, and point them to your development workspaces.

The normal libraries look like:

```bash
$ ls -l ~/.xsh/lib
total 0
lrwxr-xr-x  1 alex  staff  33 Oct 14 11:57 aws -> /Users/alex/.xsh/repo/xsh-lib/aws
lrwxr-xr-x  1 alex  staff  34 Oct 10 15:07 x -> /Users/alex/.xsh/repo/xsh-lib/core
```

The development libraries look like:

```bash
$ ls -l ~/.xsh/lib-dev
total 0
lrwxr-xr-x  1 alex  staff  32 Sep  4 16:36 aws -> /Users/alex/projects/xsh-lib/aws
lrwxr-xr-x  1 alex  staff  33 Sep  4 16:36 x -> /Users/alex/projects/xsh-lib/core
```

Then the dev mode is ready to use.
Enable dev mode by setting an environment variable: `XSH_DEV`.

Values for XSH_DEV:
```
1:      Call current called xsh utility from the development library.
<LPUR>: Call the matching xsh utilities from the development library.
```

Example:

```bash
$ XSH_DEV=1 xsh /string/upper foo
```



## 6. Where to find xsh Libraries

1. Check out the repositories under [official xsh library site](https://github.com/xsh-lib).

1. Search Github repositories with the keyword `xsh-lib-`.



## 7. TODO

* Dependency

* Library registration

* Document generation

* Test Case framework
