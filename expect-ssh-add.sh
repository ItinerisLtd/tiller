#!/usr/bin/expect -f

set file_name [lindex $argv 0]
set passphrase [lindex $argv 1]

spawn ssh-add /root/.ssh/$file_name
expect "Enter passphrase"
send $passphrase"\n"
expect "Identity added"
interact
