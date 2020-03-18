#!/bin/bash --

case $1 in
  bootstrap|recreate|upgrade)
	expect <<EOF
	set timeout 300
	spawn make $1
	expect "Enter a value:"
	send "yes\r"
	expect "continue connecting (yes/no)?"
	send "yes\r"
	expect "System is up"
	puts "automatic \'make $1\' done"
EOF
    ;;
  shutdown)
	expect <<EOF
	set timeout 300
	spawn make image destroy
	expect "Enter a value:"
	send "yes\r"
	expect "Destroy complete!"
	puts "automatic \'make image destroy\' done"
EOF
    ;;
esac