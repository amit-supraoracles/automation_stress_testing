#!/bin/bash

RPC_URL=http://localhost:27001/
DEMO2_ACCOUNT_ADDRESS="0x923d7841fab8617ae8f3e2b0f99f386bab4400a4945aa5d094ddc0d943301c77"
TEMP_ACCOUNTS_ADDRESS=(
    "0x46a3b4c126c63c51365d2b346aa0ec3045b32adec0bd6d6043b76457e490b625"
    "0x3126476fe7f9a7e9b854bc99d686c955d61bbb260b9a5385051f4999b9532c31"
    "0x73977cb3603572273523019c97d2979d33fba0b4576bc1fd66ea00c3014f7bcc"
    "0x918ed5ea8ef69f48de35bcf316578ccb0958202477dba129fbbd776efea2c010"
    "0x63f72cfff2b805f7e288809b4bf4fb975806dd0c8d70645ac039a3a3a7a1f049"
)

# Funding test accounts
for account_address in "${TEMP_ACCOUNTS_ADDRESS[@]}"; do
    curl -X 'GET' \
        "$RPC_URL"'rpc/v1/wallet/faucet/'"$account_address" \
        -H 'accept: application/json' | jq
done

# Invoke
supra move tool run --function-id "0x923d7841fab8617ae8f3e2b0f99f386bab4400a4945aa5d094ddc0d943301c77::target_order::auto_limit_order" \
    --args u32:1 u128:2000 u8:0 u32:2 u128:50 u8:1 u8:2 u64:1000000 u8:1 u64:1 u64:1

# supra move tool run --function-id "0x923d7841fab8617ae8f3e2b0f99f386bab4400a4945aa5d094ddc0d943301c77::supra_oracle_storage::mock_price_feed" \
#     --args u32:2 u128:1000 u16:6 u64:0 u64:0
curl -X POST "https://rpc-evmstaging.supra.com/rpc/v1/eth" \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
