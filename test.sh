#!/bin/bash

set -e -o pipefail

xsh log info 'xsh versions'
xsh versions

xsh log info 'xsh log info XSH_HOME: $XSH_HOME'
xsh log info XSH_HOME: $XSH_HOME

xsh log info 'xsh help'
xsh help

xsh log info 'xsh help help'
xsh help help

xsh log info 'xsh debug echo Testing xsh debug'
xsh debug echo 'Testing xsh debug'

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

xsh log info 'xsh /string/upper'
[[ $(xsh /string/upper Hello World) == "HELLO WORLD" ]]

xsh log info 'xsh imports /date/adjust'
xsh imports /date/adjust

xsh log info 'type -t x-date-adjust'
[[ $(type -t x-date-adjust) == function ]]

xsh log info 'test -n $XSH_X_DATE__POSIX_FMT'
[[ -n $XSH_X_DATE__POSIX_FMT ]]

xsh log info 'xsh unimports /date/adjust'
xsh unimports /date/adjust

xsh log info 'type -t x-date-adjust'
[[ $(type -t x-date-adjust) == "" ]]

xsh log info 'xsh unload xsh-lib/core'
xsh unload xsh-lib/core

exit
