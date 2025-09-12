#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${1:?Usage: $0 <user> <host> [<key_name>]}"
TARGET_HOST="${2:?Usage: $0 <user> <host> [<key_name>]}"
SSH_KEY_NAME="${3:-id_rsa}"

echo $TARGET_USER
echo $TARGET_HOST
echo $SSH_KEY_NAME

if [ ! -f ~/.ssh/${SSH_KEY_NAME} ]; then
    ssh-keygen -t rsa -C "${SSH_KEY_NAME}" -f ~/.ssh/${SSH_KEY_NAME} -q -N ""
fi
cat ~/.ssh/${SSH_KEY_NAME}.pub | ssh ${TARGET_USER}@${TARGET_HOST} "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R go= ~/.ssh && cat >> ~/.ssh/authorized_keys"
