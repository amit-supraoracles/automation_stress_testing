#!/bin/bash


QA_CLI_PATH="/home/codezeros/Documents/SupraFA/smr-moonshot/target/release/qa_cli"
ACCOUNT_STORE_FILE_PATH="/home/codezeros/Documents/RemoteStressTest/0_STRESS_TEST/automation-network-benchmark-master/scripts/remote_files/asdf/account_stores.json"

echo "Executing Storage Creation"

RUST_BACKTRACE=1 RUST_LOG="off,qa_cli=debug" "$QA_CLI_PATH" benchmark burst-model \
    --rpc-url https://move-stress-nw-1565.supra.com/ \
    --total-rounds 1 --burst-size 10 --cool-down-duration 5 \
    --tx-sender-account-store-file "$ACCOUNT_STORE_FILE_PATH" \
    --tx-sender-start-index 0 --tx-sender-end-index 9 \
    --static-payload-file-path ../data/automation_limit_order_task_payload_fail.json \
    --should-automation-tx-type-payload \
    --automation-task-max-gas-amount 190 --automation-task-gas-price-cap 100 \
    --automation-fee-cap-for-epoch 2500000 \
    --automation-expiration-duration-secs 3600 \
    --max-polling-attempts 5 --polling-wait-time-in-ms 200 \
    --tx-request-retry 5 --wait-before-request-retry-in-ms 100 \
    --total-http-clients-instance 1 \
    --total-class-groups 10 \
    --generate-metrics-file-path ../data/temp.json \
    > "../data/benchmark_200.log"

echo "Completed run with expiration"
echo "All tasks completed."