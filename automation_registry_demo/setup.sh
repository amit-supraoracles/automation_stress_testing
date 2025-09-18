#!/bin/bash

SUPRA_CLI=/home/codezeros/Documents/SupraFA/smr-moonshot/target/release/supra
# RPC_URL=http://34.38.116.129:26000/
RPC_URL=http://localhost:27001/
DEMO1_ACCOUNT_ADDRESS="0x1b246e83ca8f538f59eb32c5db273cae5b79e21e2fd22faa6fe95ee1039f1342"
DEMO2_ACCOUNT_ADDRESS="0x2eb858c25ad218ed9ce9d03b6a02ef51fa14d570f882cc5a9937c483c46c5e76"
DEMO1_ACCOUNT_PROFILE_NAME="foundation_1"
DEMO2_ACCOUNT_PROFILE_NAME="foundation_2"
PROFILE_PASSWORD="Buggy#123"
WAIT_TIME_AFTER_ACTION=1

send_supra_tx() {
    local TX_RELATED_COMMAND="$1"

    expect <<EOF
spawn ${TX_RELATED_COMMAND}

expect "Enter your password"
send "${PROFILE_PASSWORD}\n"
expect "Proceed with a Max Gas Amount"
send "\n"
expect "Proceed with a Gas Unit Price"
send "\n"
expect eof
EOF

    sleep "$WAIT_TIME_AFTER_ACTION"
}

main() {
    echo "Funding module accounts"
    curl -X 'GET' \
        "$RPC_URL"'rpc/v1/wallet/faucet/'"$DEMO1_ACCOUNT_ADDRESS" \
        -H 'accept: application/json' | jq
    curl -X 'GET' \
        "$RPC_URL"'rpc/v1/wallet/faucet/'"$DEMO2_ACCOUNT_ADDRESS" \
        -H 'accept: application/json' | jq

    cd demo1 || exit 1
    echo "Deploying demo1 module for test coins"
    send_supra_tx "${SUPRA_CLI} move tool publish --profile ${DEMO1_ACCOUNT_PROFILE_NAME} --rpc-url ${RPC_URL}"

    cd ../demo2 || exit 1
    echo "Deploying demo2 module"
    send_supra_tx "${SUPRA_CLI} move tool publish --profile ${DEMO2_ACCOUNT_PROFILE_NAME} --rpc-url ${RPC_URL}"

    echo "Mocking Test Coins price"
    send_supra_tx "${SUPRA_CLI} move tool run --function-id ${DEMO2_ACCOUNT_ADDRESS}::supra_oracle_storage::mock_price_feed \
    --args u32:1 u128:1000 u16:8 u64:0 u64:0 \
    --profile ${DEMO2_ACCOUNT_PROFILE_NAME} --rpc-url ${RPC_URL}"

    send_supra_tx "${SUPRA_CLI} move tool run --function-id ${DEMO2_ACCOUNT_ADDRESS}::supra_oracle_storage::mock_price_feed \
    --args u32:2 u128:100 u16:6 u64:0 u64:0 \
    --profile ${DEMO2_ACCOUNT_PROFILE_NAME} --rpc-url ${RPC_URL}"

    echo "Calling auto limit order for test"
    send_supra_tx "${SUPRA_CLI} move tool run --function-id ${DEMO2_ACCOUNT_ADDRESS}::target_order::auto_limit_order \
    --args u32:1 u128:2000 u8:0 u32:2 u128:50 u8:1 u8:2 u64:1000000 u8:1 u64:1 u64:99999999 \
    --profile ${DEMO2_ACCOUNT_PROFILE_NAME} --rpc-url ${RPC_URL}"
}

main "$@"
