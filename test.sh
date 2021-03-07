#!/bin/bash

set -e

xsh log info 'xsh log info xsh version'
xsh log info xsh version

xsh log info 'xsh versions'
xsh versions

xsh log info 'xsh log info XSH_HOME: $XSH_HOME'
xsh log info XSH_HOME: $XSH_HOME

xsh log info 'xsh help'
xsh help

xsh log info 'xsh help help'
xsh help help

xsh log info 'xsh debug echo Testing xsh debug'
xsh debug echo Testing xsh debug

xsh log info 'xsh list'
xsh list

xsh log info 'xsh load xsh-lib/core'
xsh load xsh-lib/core

xsh log info 'xsh list /'
xsh list /

xsh log info 'xsh help /string/upper'
xsh help /string/upper

xsh log info 'xsh help -c /string/upper'
xsh help -c /string/upper

xsh log info 'xsh /string/upper Hello World'
xsh /string/upper Hello World

xsh log info 'xsh imports /string/lower'
xsh imports /string/lower

xsh log info 'x-string-lower Hello World'
x-string-lower Hello World

xsh log info 'xsh unimports /string/lower'
xsh unimports /string/lower

xsh log info 'x-string-lower Hello World 2>/dev/null || test $? -ne 0'
x-string-lower Hello World 2>/dev/null || test $? -ne 0

xsh log info 'xsh unload xsh-lib/core'
xsh unload xsh-lib/core

exit
