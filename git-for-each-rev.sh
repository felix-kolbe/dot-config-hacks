#!/usr/bin/env bash
# test_commits.sh
# Use: ./test_commits.sh origin/master..master

while read -r rev; do
    git checkout "$rev"
    if ! git submodule update && make clean && make; then
        >&2 echo "Commit $rev failed"
        exit 1
    fi
done < <(git rev-list "$1")
