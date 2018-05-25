#!/usr/bin/expect -f

set file_name [lindex $argv 0]
set passphrase [lindex $argv 1]

spawn ssh-add /root/.ssh/$file_name
expect "Enter passphrase for /root/.ssh/$file_name:"
send $passphrase\n
expect "Identity added"
interact
