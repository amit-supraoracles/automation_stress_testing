#!/bin/bash

# For governance proposal
SUPRA_CLI_PATH=../../smr-moonshot/target/release/supra
RPC_URL="http://localhost:27001/"
# RPC_URL="http://34.38.116.129:26000/"
FOUNDATION_OWNERS_ACCOUNTS_STORE_FILE_PATH="../../smr-moonshot/remote_env/Logs/owners"
PROFILE_PASSWORD="Buggy#123"
# FOUNDATION_OWNERS_ACCOUNTS_STORE_FILE_PATH="../data/foundation_owners"
METADATA_URL="https://raw.githubusercontent.com/Entropy-Foundation/smr-moonshot/refs/heads/dev/remote_env/move_workspace/proposals/proposal_one.json?token=GHSAT0AAAAAACMRJFS7USRZOG7RLKDBZYTK2BLKRBA"
COMPILED_SCRIPTS_PATH="../governance_proposal_script/build/governance_proposal_script/bytecode_scripts"
PROPOSAL_SCRIPT_PATH="${COMPILED_SCRIPTS_PATH}/supra_framework_upgarde_proposal.mv"
FRAMEWORK_UPGRADE_PROPOSAL_SCRIPT_PATH="${COMPILED_SCRIPTS_PATH}/supra_framework_upgarde_proposal.mv"
EXPECTED_PRPOPSAL_ID="9"
file_paths=("$FOUNDATION_OWNERS_ACCOUNTS_STORE_FILE_PATH"/*)
WAIT_TIME_AFTER_ACTION=2

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
    # Creating a proposal
    echo "${file_paths[0]} creating proposal"
    export SUPRA_HOME=${file_paths[0]}
    expect <<EOF
spawn ${SUPRA_CLI_PATH} governance propose \
    --metadata-url ${METADATA_URL} \
    --compiled-script-path ${PROPOSAL_SCRIPT_PATH} \
    --rpc-url ${RPC_URL} \
    --is-multi-step
 
expect "yes/no"
send "y\n"
expect "Enter your password"
send "${PROFILE_PASSWORD}\n"
expect "Proceed with a Max Gas Amount"
send "\n"
expect "Proceed with a Gas Unit Price"
send "\n"
expect eof
EOF
    sleep "$WAIT_TIME_AFTER_ACTION"

    # Voting for the proposal
    i=1
    while [ "$i" -lt ${#file_paths[@]} ]; do
        echo "${file_paths[$i]} voting for proposal"
        export SUPRA_HOME=${file_paths[$i]}
        send_supra_tx "${SUPRA_CLI_PATH} governance vote --proposal-id ${EXPECTED_PRPOPSAL_ID} --yes \
            --rpc-url ${RPC_URL}"

        ((i++))
    done

    # Executing proposal script
    echo "${file_paths[0]} executing proposal"
    export SUPRA_HOME=${file_paths[0]}
    send_supra_tx "${SUPRA_CLI_PATH} move tool run-script --compiled-script-path ${PROPOSAL_SCRIPT_PATH} \
        --args u64:${EXPECTED_PRPOPSAL_ID} \
        --rpc-url ${RPC_URL}"

    # # Executing framework upgrade proposal script
    # echo "${file_paths[0]} executing proposal"
    # export SUPRA_HOME=${file_paths[0]}
    # send_supra_tx "${SUPRA_CLI_PATH} move tool run-script --compiled-script-path ${FRAMEWORK_UPGRADE_PROPOSAL_SCRIPT_PATH} \
    #     --args u64:${EXPECTED_PRPOPSAL_ID} \
    #     --rpc-url ${RPC_URL}"

}
main "$@"
