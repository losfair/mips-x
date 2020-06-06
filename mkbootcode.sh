#!/bin/sh

SSH_REMOTE="leakyinvariant@10.211.55.8"

ssh "$SSH_REMOTE" "rm -r /tmp/mips-x-build || true; mkdir /tmp/mips-x-build" || exit 1
scp -r ./bootcode "$SSH_REMOTE:/tmp/mips-x-build" || exit 1
ssh "$SSH_REMOTE" "/tmp/mips-x-build/bootcode/build.sh" || exit 1
scp "$SSH_REMOTE:/tmp/mips-x-build/bootcode/{code.txt,code.dump}" ./ || exit 1
