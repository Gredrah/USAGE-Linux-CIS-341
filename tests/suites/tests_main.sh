#!/usr/bin/env bash

runall() {
	bats tests/engine/ tests/access/ tests/daemon
}

usage() {
	echo "Please run ./tests_main.sh [engine, access, daemon]"
	echo "Use no arguments for all test suites, with confirmation requested unless using ./tests_main.sh all"
}

set -e
if [[ $# -eq 1 ]] ; then
	if [[ $1 == engine ]] ; then
		bats tests/engine/
	elif [[ $1 == access ]] ; then
		bats tests/access/
	elif [[ $1 == daemon ]] ; then
		bats tests/daemon/
	elif [[ $1 == all ]] ; then
		runall
	else
		usage
		exit 1
	fi
elif [[ $# -eq 0 ]] ; then
	echo -n "Run all test suites? yN"
	read -r yN
	if [[ "$yN" == y || "$yN" == Y ]] ; then
		runall
	else
		exit 0
	fi
else
	usage
	exit 1
fi
