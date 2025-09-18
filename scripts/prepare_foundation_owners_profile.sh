#!/bin/bash

SUPRA_CLI_PATH=../../smr-moonshot/target/devopt/supra
FOUNDATION_OWNERS_ACCOUNTS_STORE_FILE_PATH="../data/foundation_owners"
FOUNDATION_OWNERS_PROFILE_NAME="temp"
file_paths=("$FOUNDATION_OWNERS_ACCOUNTS_STORE_FILE_PATH"/*)

i=0
while [ "$i" -lt ${#file_paths[@]} ]; do
    cur_path=${file_paths[$i]}
    secret_key=$(jq -r ".ed25519_secret_key" "$cur_path"/smr_secret_key.pem)
    rm -rf "${cur_path:?}/"*
    export SUPRA_HOME="${cur_path}"
    echo "${secret_key}"
    "$SUPRA_CLI_PATH" profile new "$FOUNDATION_OWNERS_PROFILE_NAME" "${secret_key}"
    ((i++))
done