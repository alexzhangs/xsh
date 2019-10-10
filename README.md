# e<span style="color:red">X</span>tension of ba<span style="color:red">SH</span>

xsh is an e<span style="color:red">__x__</span>tension of ba<span style="color:red">__sh__</span>. It works as a bash library framework.

xsh is aimed to provide a uniform and easy way to reuse bash code, like what a library does.

xsh - this repository, in a narrow sense, is not a library itself, it's just a framework, in a broad sense, xsh along with other repositories, such as `xsh-lib/core`, as a whole, is a bash library with a framework.



## 1. Status

Currently this project is at version 0.x, and still in "heavy" development.



## 2. Philosophy

* Reuse the shell code previously written, provide a uniform way to organize the code, document the code, format the code, execute the code, even the way you write the code. As a result, some of well organized bash code libraries will born.

* Easy to bootstrap(install).

  Only thing you need is bash and Git client.

  ```bash
  git clone https://github.com/alexzhangs/xsh
  bash xsh/install.sh
  ```

* Easy to invoke.

  E.g. Call a utility named `upper` under the package `string` in the library `x` :

  ```bash
  xsh x/string/upper 'hello world'

  HELLO WORLD
  ```

* Easy to understand how it works.

  __xsh framework__, in technical, is just a single function, called `xsh()`, the only function inside `xsh.sh`.

  Through `xsh()`, it's able to load/unload libraries, call utilities of libraries, and get help.

  __xsh libraries__, are some Git repositories, hosted online, contain some .sh files, called utilities, present as functions and scripts, organized with certain simple rules.

  You are able to build your own libraries with your own Git repositories.

* Easy to make your existing code a library.

  A xsh library is actually just a Git repo following some simple rules. The rules will be talked about later in the development section. Any repos following that rules could be loaded as xsh libraries.



### 2.1. What does xsh Framework Do?

* Handle the extraction of help and usage information
* Handle library update



### 2.2. What do xsh Libraries Do?

* Provide container for utilities
* Provide rules for organizing utilities by packages
* Handle versioning

The xsh framework supports both public and private libraries.



### 2.3 What do xsh Utilities Do?

* Provide fundamental function
* Provide help and usage information
* Handle temporary files
* Handle logs
* Handle output

Of cause, some of above topics could be built as libraries, packages or utilities too.



## 3. xsh Bootstrap/Installation

Only thing you need is bash and Git client.

```bash
git clone https://github.com/alexzhangs/xsh
bash xsh/install.sh
```



## 4. xsh Usage

Before you can really do something useful with xsh, you must load some libraries.



### 4.1. Load xsh Libraries

Use `xsh load` command to load a library.

Loading the latest tagged version of library [xsh-lib/core](https://github.com/xsh-lib/core), you should issue:

```bash
xsh load xsh-lib/core

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

Loading the latest development state of library [xsh-lib/core](https://github.com/xsh-lib/core) on default branch `master`, you should issue:

```bash
xsh load -b master xsh-lib/core
```

After the lib is loaded, you can use `xsh list` command to list all loaded libraries.

```bash
xsh list

x (0.1.0) => xsh-lib/core
```

To list all the utilities of the library `x`, use:

```bash
xsh list x

[SCRIPT] x/log/filter
[FUNCTIONS] x/string/lower
[FUNCTIONS] x/string/random
[FUNCTIONS] x/string/upper
[FUNCTIONS] x/string/uuid
...
```



#### 4.1.1. Update the Loaded xsh Libraries

Use `xsh update` command to update loaded libraries.

To update the previously loaded library `xsh-lib/core`, simply issue:

```
xsh update xsh-lib/core

Deleted tag '0.1.0' (was 5e7dcfb)
From https://github.com/xsh-lib/core
 * [new tag]         0.1.0      -> 0.1.0
__xsh_git_force_update: INFO: Already at the latest version: 0.1.0.
```



#### 4.1.2. Unload the loaded xsh Libraries

Use `xsh unload` command to unload loaded libraries.

To unload the previously loaded library `xsh-lib/core`, simply issue:

```bash
xsh unload xsh-lib/core
```



### 4.2. Invoke xsh Utilities

There are 3 methods to invoke xsh utilities.

Before to talk about that, lets get familiar with the glossary `LPUE`, `LPUR` and `LPUC`.

* LPUE stands for `Lib/Package/Util Expression`,  a LPUE example for the library `xsh-lib/core` is `x/string/upper`.

* LPUR stands for `Lib/Package/Util Regex`,  a LPUR example for the library `xsh-lib/core` is `x/string` which is matching all the utilities under the package string.

* LPUC stands for `Lib/Package/Util Callable`, a LPUC example for the library `xsh-lib/core` is `x-string-upper`.

Now lets get back the 3 methods:

1. Call an individual LPUE.

   The syntax:

   ```bash
   xsh <LPUE> [options]
   ```

   A sample:

   ```bash
   xsh x/string/upper 'hello world'

   HELLO WORLD
   ```

2. Call LPUEs in batch, you can't pass any options.

   The syntax:

   ```bash
   xsh call <LPUE> ...
   ```

   A sample:

   ```bash
   xsh call x/string/random x/string/uuid

   e30e865ed22f3ef9
   4be36c77-e507-4eee-9075-1aa259c1613e
   ```

3. Call a LPUC without the leading `xsh` command.

   The syntax:

   ```bash
   <LPUC> [options]
   ```

   In order to call a LPUC directly, you must import the LPUE first.

   Use command `xsh import` to import LPUEs, then you can call them directly as the syntax: `<lib>-<package>-<util>`.

   A sample:

   ```bash
   xsh import x/string

   x-string-upper 'hello world'
   HELLO WORLD

   x-string-uuid
   4be36c77-e507-4eee-9075-1aa259c1613e
   ```



### 4.3. Update xsh itself

See the current xsh version:

```bash
xsh version

0.1.4
```

List all available xsh versions(tags):

```bash
xsh versions

0.1.0
0.1.1
0.1.2
0.1.3
0.1.4
```

Update xsh to the latest tagged version:

```bash
xsh upgrade
```

Update xsh to a historical tagged version:

```bash
xsh upgrade -t <tag>
```



### 4.4. Get Help

See the usage info of xsh itself:

```bash
xsh help
```

See the usage info of xsh utilities by LPUR:

```bash
xsh help <LPUR>
```

List all loaded libraries:

```bash
xsh list

x (0.1.0) => xsh-lib/core
```

List utilities by LPUR:

```bash
xsh list <LPUR>
```

List all utilities of all libraries:

```
xsh list '*'
```



## 5. Development



### 5.1. How to Make Your Own xsh Libraries?

The directory structure and files of a sample library looks like this:

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

Let each of your functions be a single `.sh` file, named as the same as the function name, put them under the directory `functions`, you are free to organize the sub directories, the sub directory in this sample is `string` and `log`, they are called `packages`.



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

You will need to follow the comment style in order to let xsh generate help info.

The function should be started with the exact syntax:

```
function <name> ()
```

It's pretty the same with scripts files except that you don't have to define functions inside the script.



#### 5.1.3. Commit the code and test it

Push the code to a Git repo, for example Github, on branch `master`, then the library is ready for test.

Load the sample library `xsh-lib-sample` on Github:

Note: Option `-b master` is neccessary to tell that you are loading the latest untagged version for testing purpose.

```bash
xsh load -b master yourusername/xsh-lib-sample
```

Or if the Git repo isn't on Github, issue:

```
xsh load -s http://yourgitserver.com -b master yourusername/xsh-lib-sample
```

Then they are able to be called as:

```bash
xsh smpl/string/lower
xsh smpl/string/upper
xsh smpl/log/filter
```



#### 5.1.4. Publish the library

In order to tell world that the library is ready, you have to make at least one Git tag to publish the library.

To use [Semantic Versioning](https://semver.org) for the tag name is recommended.

To make an annotated tag `1.0.0` on the latest commit of branch `master`, issue:

```
git tag -a -m 'v1.0.0' 1.0.0
```

Then the library is ready.

Load the published sample library `xsh-lib-sample` on Github:

```bash
xsh load yourusername/xsh-lib-sample
```



### 5.2. Debugging

Debug the called utility:

```bash
XSH_DEBUG=1 xsh /string/upper foo
```

Debug the matching utilities:

```
XSH_DEBUG='/string' xsh /string/upper foo
```



## 6. Where to find xsh Libraries

1. Check out the repositories under [official xsh library site](https://github.com/xsh-lib).

1. Search Github repositories with keyword `xsh-lib-`.



## 7. TODO

* Dependency

* Library registration

* Document generation

* Test Case framework

* Adopting CI - GoCD


