#!/bin/bash


# expirations=(3600 1900 3000 3100 2000 5600 5600 5400 5600 5400 3000 2000 5400 3000 5400) #28_000

expirations=(3600)

echo "Registering tasks"

QA_CLI_PATH="/home/codezeros/Documents/SupraFA/smr-moonshot/target/release/qa_cli"
ACCOUNT_STORE_FILE_PATH="/home/codezeros/Documents/RemoteStressTest/ssh/asdf/account_stores.json"

# Loop through each expiration value
for expiration in "${expirations[@]}"; do
    echo "Executing Task Registration Set with expiration: $expiration"

    RUST_BACKTRACE=1 RUST_LOG="off,qa_cli=debug" "$QA_CLI_PATH" benchmark burst-model \
        --rpc-url https://move-stress-nw-1565.supra.com/ \
        --total-rounds 1 --burst-size 1 --cool-down-duration 20 \
        --tx-sender-account-store-file "$ACCOUNT_STORE_FILE_PATH" \
        --tx-sender-start-index 0 --tx-sender-end-index 1999 \
        --static-payload-file-path ../data/automation_limit_task_payload.json \
        --should-automation-tx-type-payload \
        --automation-task-max-gas-amount 2000 --automation-task-gas-price-cap 100 \
        --automation-fee-cap-for-epoch 2500000 \
        --automation-expiration-duration-secs "$expiration" \
        --max-polling-attempts 5 --polling-wait-time-in-ms 200 \
        --tx-request-retry 5 --wait-before-request-retry-in-ms 100 \
        --total-http-clients-instance 1 \
        --total-class-groups 10 \
        --generate-metrics-file-path ../data/temp.json \
        > "../data/benchmark_$expiration.log"

    echo "Completed run with expiration: $expiration"
    echo "Waiting for 10 seconds before next run..."
    sleep 10
done

echo "All tasks completed."
