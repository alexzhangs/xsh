# e<span style="color:red">X</span>tension of ba<span style="color:red">SH</span>

xsh is an e<span style="color:red">__x__</span>tension of ba<span style="color:red">__sh__</span>. It works as a bash library framework.

xsh is aimed to provide an uniform and easy way to reuse bash code, like what a library does.

xsh - this repository, in a narrow sense, is not a library itself, it's just a framework, in a broad sense, xsh along with other repositories, such as xsh-lib-core, as a whole, is a bash library with a framework.



## Status

Currently this project is at version 0.x, and still in "heavy" deveolpment.



## Philosophy

* Reuse the shell code previously written, provide an uniform way to organize the code, document the code, format the code, execute the code, even the way you write the code. As a result, some of well organized bash code libraries will born.

* Easy to bootstrap(install).

  Only thing you need is bash and Git client.

  ```bash
  git clone https://github.com/alexzhangs/xsh
  bash xsh/install.sh
  ```

* Easy to invoke.

  e.g. Call a utility named `upper` under the package `array` in the library `x` :

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

  A xsh library is acturally just a Git repo following some simple rules. The rules will be talked about later in the development section. Any repoes following that rules could be loaded as xsh libraries.



### What does xsh Framework Do?

* Handle the extraction of help and usage information

* Handle library update



### What do xsh Libraries Do?

* Provide container for utilities

* Provide rules for organizing utilities by packages

The xsh framework supports both public and private libraries.



### What do xsh Utilities Do?

* Provide fundamental function

* Provide help and usage information

* Handle temporary files

* Handle logs

* Handle output

Of cause, some of above topics could be built as libraries, packages or utilities too.



## xsh Bootstrap/Installation

Only thing you need is bash and Git client.

```bash
git clone https://github.com/alexzhangs/xsh
bash xsh/install.sh
```



## xsh Usage

Before you can really do something useful with xsh, you must load some libraries.



### Load xsh Libraries

Use `xsh load` command to load a library, for example, loading library [xsh-lib-core](https://github.com/alexzhangs/xsh-lib-core) on default branch `master`, and give a short lib name `x`, you should issue:

```bash
xsh load -r https://github.com/alexzhangs/xsh-lib-core x

Cloning into '/Users/alex/.xsh/lib/x'...
remote: Enumerating objects: 12, done.
remote: Counting objects: 100% (12/12), done.
remote: Compressing objects: 100% (10/10), done.
remote: Total 887 (delta 2), reused 7 (delta 1), pack-reused 875
Receiving objects: 100% (887/887), 110.90 KiB | 25.00 KiB/s, done.
Resolving deltas: 100% (369/369), done.
```

After the lib is loaded, you can use `xsh list` command to list all loaded libraries and utilities.

```bash
xsh list

[SCRIPT] x/log/filter
[FUNCTIONS] x/string/lower
[FUNCTIONS] x/string/random
[FUNCTIONS] x/string/upper
[FUNCTIONS] x/string/uuid
...
```



#### Upgrade the Loaded xsh Libraries

Use `xsh update` command to update loaded libraries.

To update the previously loaded library xsh-lib-core, simply issue:

```
xsh update x

HEAD is now at 9706514 use Array way to get Array index
```



#### Unload the loaded xsh Libraries

Use `xsh unload` command to unload loaded libraries.

To unload the previously loaded library xsh-lib-core, simply issue:

```bash
xsh unload x
```



### Invoke xsh Utilities

There are 3 methods to invoke xsh utilities.

Before to talk about that, lets get familier with the glossary `LPUE` and `LPUC`.

* LPUE stands for `Lib/Package/Util Expression`,  a LPUE example for the library xsh-lib-core is `x/string/upper`.

* LPUC stands for `Lib/Package/Util Callable`, a LPUC example for the library xsh-lib-core is `x-string-upper`.

Now lets get back the 3 methods:

1. Call an individuel LPUE.

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
   xsh import x/string/*

   x-string-upper 'hello world'
   HELLO WORLD

   x-string-uuid
   4be36c77-e507-4eee-9075-1aa259c1613e
   ```



## Development



### How to Make Your Own xsh Libraries?

The directory structure and files of a sample library looks like this:

``` 
xsh-lib-sample/
├── functions
│   └── string
│       └── lower.sh
│       └── random.sh
│       └── upper.sh
│       └── uuid.sh
└── scripts
    └── log
        └── filter.sh
```

Let each of your functions be a single .sh file, named as the same as the function name, put them under the directory `functions`, you are free to organize the sub directories, the sub directory in this sample is `string` and `log`, they are called `packages`.

Below is the code of file `xsh-lib-sample/functions/string/upper.sh`.

You will need to follow the code style in order to let xsh generate help info.

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
    echo "$@" | xsh /string/pipe/upper
}
```

It's pretty the same with scripts files except that you don't have to define functions inside the script.

Push them to a Git repo, Github for example, then the library is ready.

Load the sample library `xsh-lib-sample` and make a short name called `smpl`:

```bash
xsh load -r https://github.com/yourusername/xsh-lib-sample smpl
```

Then they are able to be called as:

```bash
xsh smpl/string/lower
xsh smpl/string/upper
xsh smpl/log/filter
```



## TODO

* Versioning

  Refer to: https://semver.org

* Dependency

* Library regsitration

* Document generation

* Test Case framework

* Adopting CI - GoCD


