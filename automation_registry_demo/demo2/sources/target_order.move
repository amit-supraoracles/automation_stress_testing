module demo2::target_order {
    use std::bcs::to_bytes;
    use std::signer;
    use aptos_std::aptos_hash::keccak256;
    use aptos_std::table;

    use supra_framework::timestamp;

    use demo2::supra_oracle_storage;

    // use dexlyn_swap::router;
    // use supra_framework::coin;
    // use supra_framework::supra_account;
    /// Error codes
    const EINVALID_OPERATION_ID: u64 = 1;
    // Operation ID must be either 0 or 1
    const EINVALID_ACTION_ID: u64 = 2;
    // Action ID must be either 0 or 1
    const EINVALID_TOKEN_ID: u64 = 3;
    // Token ID must be valid
    // Invalid connector id, it should be 1 or 2
    const EINVALID_CONNECTOR_ID: u64 = 4;

    /// Operator constants
    const LESS_OR_EQUAL: u8 = 0;
    const GREATER_OR_EQUAL: u8 = 1;

    /// Logical operation constants
    const NONE: u8 = 0;
    const OR: u8 = 1;
    const AND: u8 = 2;

    const U32_MAX: u32 = 4_294_967_295;

    /// Structure to keep track of automation state
    struct AutomationStateInfo has key {
        last_time_checked: u64,
        // Last execution timestamp
        counter: u64,
        // Number of times the automation has been executed
    }

    /// Structure to keep track of automation state
    struct AutomationStateInfoNew has key {
        last_time_checked: u64,
        // Last execution timestamp
        counter: table::Table<vector<u8>, u64>,
        // Number of times the automation has been executed
    }

    struct BytesData has drop {
        token_id1: u32,
        target_price1: u128,
        operator_id1: u8,
        token_id2: u32,
        target_price2: u128,
        operator_id2: u8,
        connect_operator_id: u8,
        target_token_amount: u64,
        action_id: u8,
        time_duration: u64,
        counter: u64
    }

    /// Function to automate limit orders
    public entry fun auto_limit_order(
        user: &signer,
        token_id1: u32,
        target_price1: u128,
        operator_id1: u8,
        token_id2: u32,
        target_price2: u128,
        operator_id2: u8,
        connect_operator_id: u8,
        target_token_amount: u64,
        action_id: u8,
        time_duration: u64,
        counter: u64 // 0 means no execution limit, otherwise executes up to the specified count
    ) acquires AutomationStateInfoNew {
        let user_addr = signer::address_of(user);
        let current_time = timestamp::now_seconds();

        // Initialize automation state if not exists
        if (!exists<AutomationStateInfoNew>(user_addr)) {
            // move_to(user, AutomationStateInfo { last_time_checked: 0, counter: 0 });
            move_to(user, AutomationStateInfoNew { last_time_checked: 0, counter: table::new() });
        };

        let bytes = BytesData {
            token_id1, target_price1, operator_id1, token_id2, target_price2, operator_id2, connect_operator_id, target_token_amount, action_id, time_duration, counter
        };
        let bytes = to_bytes(&bytes);
        let bytes_keccake = keccak256(bytes);

        // Enforce time-based execution constraints
        if (time_duration > 0) {
            let automation_state = borrow_global_mut<AutomationStateInfoNew>(user_addr);
            if ((current_time - automation_state.last_time_checked) < time_duration) {
                return // Exit if not enough time has passed
            } else {
                automation_state.last_time_checked = current_time;
            }
        };

        // If both token IDs are max value, execute unconditionally
        if (token_id1 == U32_MAX && token_id2 == U32_MAX) {
            perform_action(user, action_id, target_token_amount, counter, bytes_keccake);
            return
        };

        assert!(token_id1 != U32_MAX, EINVALID_TOKEN_ID); // Ensure first token is valid
        assert!((connect_operator_id == NONE || token_id2 != U32_MAX), EINVALID_TOKEN_ID);
        assert!(token_id2 == U32_MAX || connect_operator_id != NONE, EINVALID_CONNECTOR_ID);

        let oracle_holder_address = supra_oracle_storage::get_oracle_holder_address();
        let (token_id1_price, _, _, _) = supra_oracle_storage::get_price(oracle_holder_address, token_id1);
        let condition1 = check_condition(token_id1_price, target_price1, operator_id1);

        // Evaluate conditions based on logical operators
        if (connect_operator_id == NONE) {
            if (condition1) {
                perform_action(user, action_id, target_token_amount, counter, bytes_keccake);
            };
            return
        };
        let (token_id2_price, _, _, _) = supra_oracle_storage::get_price(oracle_holder_address, token_id2);
        let condition2 = check_condition(token_id2_price, target_price2, operator_id2);
        if (connect_operator_id == OR && (condition1 || condition2)) {
            perform_action(user, action_id, target_token_amount, counter, bytes_keccake);
            return
        };
        if (connect_operator_id == AND && (condition1 && condition2)) {
            perform_action(user, action_id, target_token_amount, counter, bytes_keccake);
            return
        };
    }

    /// Function to check if a condition is met based on operator and target price
    fun check_condition(token_id_current_price: u128, target_price: u128, operator_id: u8): bool {
        if (operator_id == LESS_OR_EQUAL && token_id_current_price > target_price ||
            operator_id == GREATER_OR_EQUAL && token_id_current_price < target_price) {
            false
        } else { true }
    }

    /// Function to perform buy/sell actions based on action ID
    fun perform_action(
        user: &signer,
        _action_id: u8,
        _target_token_amount: u64,
        req_counter: u64,
        bytes_keccake: vector<u8>
    ) acquires AutomationStateInfoNew {
        let user_addr = signer::address_of(user);

        // Enforce execution count limit
        if (req_counter > 0) {
            let automation_state = borrow_global_mut<AutomationStateInfoNew>(user_addr);
            let counter = table::borrow_mut_with_default(&mut automation_state.counter, bytes_keccake, 0);
            if (req_counter <= *counter) {
                return // Exit if execution count has been reached
            };
            *counter = *counter + 1;
        };

        // we don't care it's buy or sell since both are using same gas amount
        // This loop is exactly consuming around 47 gas unit
        let i = 0;
        let max = 10000;
        while (i < max) {
            i = i + 1;
        }

        // Perform sell action (action_id = 0)
        // if (action_id == 0) {
        //     let coin_x = coin::withdraw<X>(user, target_token_amount);
        //     let coin_out_min_val = router::get_amount_out<X, Y, Curve>(target_token_amount);
        //     let coin_y = router::swap_exact_coin_for_coin<X, Y, Curve>(coin_x, coin_out_min_val);
        //     supra_account::deposit_coins<Y>(user_addr, coin_y);
        // }
        //     // Perform buy action (action_id = 1)
        // else if (action_id == 1) {
        //     let coin_in_val_needed = router::get_amount_in<Y, X, Curve>(target_token_amount);
        //     let coin_y = coin::withdraw<Y>(user, coin_in_val_needed);
        //     let (coin_y, coin_x) = router::swap_coin_for_exact_coin<Y, X, Curve>(coin_y, target_token_amount);
        //     supra_account::deposit_coins<Y>(user_addr, coin_y);
        //     supra_account::deposit_coins<X>(user_addr, coin_x);
        // }
    }

    // it consume around 47 gas unit
    // https://rpc-autonet.supra.com/rpc/v1/transactions/866d0e5a0bb5f4985d54508b30c6f79975f4dd423e45c8148e074773c265e23d
    entry fun test_gas() {
        let i = 0;
        let max = 10000;
        while (i < max) {
            i = i + 1;
        }
    }

    // #[test(user = @0xa1, supra_framework = @supra_framework, oracle_owner = @demo2)]
    // fun test_auto_limit(
    //     user: &signer,
    //     supra_framework: &signer,
    //     oracle_owner: &signer
    // ) acquires AutomationStateInfoNew {
    //     // use dexlyn_swap::curves::Uncorrelated;
    //     use supra_framework::timestamp;
    //
    //     timestamp::set_time_has_started_for_testing(supra_framework);
    //
    //     supra_oracle_storage::initialize_for_test(oracle_owner);
    //     supra_oracle_storage::add_whitelist(oracle_owner, signer::address_of(oracle_owner));
    //     supra_oracle_storage::mock_price_feed(
    //         oracle_owner,
    //         0,
    //         95536120000000000000000,
    //         18,
    //         1740134739228,
    //         1740134739000
    //     );
    //
    //     supra_oracle_storage::mock_price_feed(
    //         oracle_owner,
    //         1,
    //         2789650000000000000000,
    //         18,
    //         1740134739228,
    //         1740134739000
    //     );
    //
    //     auto_limit_order<TestBTC, TestUSDC, Uncorrelated>(
    //         user,
    //         0,
    //         96000000000000000000000,
    //         1,
    //         1,
    //         2800000000000000000000,
    //         0,
    //         1,
    //         20000000,
    //         0,
    //         0,
    //         1
    //     );
    // }
}
