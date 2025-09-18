module demo1::auto_topup {
    use supra_framework::coin;

    /// Top-up amount must be greater than the threshold
    const ETOPUP_AMOUNT_TOO_LOW: u64 = 1;

    /// Automatically tops up the target account if its balance falls below the threshold
    public entry fun auto_topup<CoinType>(
        funder: &signer,
        target: address,
        threshold: u64,
        topup_amount: u64
    ) {
        let target_balance = coin::balance<CoinType>(target);

        // Ensure the (current + top-up) amount is greater than the threshold; otherwise, the mechanism is ineffective
        assert!((target_balance + topup_amount) > threshold, ETOPUP_AMOUNT_TOO_LOW);

        // If the target's balance is below the threshold, transfer the top-up amount from the funder
        if (target_balance < threshold) {
            coin::transfer<CoinType>(funder, target, topup_amount);
        }
    }

    #[test(demo1 = @demo1, funder = @0xc1b2, target = @0xd3e4)]
    fun test_auto_topup(demo1: &signer, funder: &signer, target: &signer) {
        use demo1::coins::TestUSDC;
        use demo1::coins;

        let threshold = 100_000;
        let topup_amount = 1_000_000;

        // Register the coin type in the system
        coins::register_coins(demo1);

        // Initialize the funder's account with tokens
        let funder_addr = aptos_std::signer::address_of(funder);
        supra_framework::account::create_account_for_test(funder_addr);
        coin::register<TestUSDC>(funder);
        coins::mint_coin<TestUSDC>(demo1, funder_addr, 100_000_000); // Mint 100M tokens to the funder

        // Initialize the target's account with some balance
        let target_addr = aptos_std::signer::address_of(target);
        supra_framework::account::create_account_for_test(target_addr);
        coin::register<TestUSDC>(target);
        coins::mint_coin<TestUSDC>(demo1, target_addr, 1_000_000); // Mint 1M tokens to the target

        // Verify the initial balance of the target account
        let target_balance = coin::balance<TestUSDC>(target_addr);
        assert!(target_balance == 1_000_000, 1);

        // Test Case 1: Since the target's balance is already above the threshold, auto-topup should not trigger
        auto_topup<TestUSDC>(funder, target_addr, threshold, topup_amount);
        let target_balance = coin::balance<TestUSDC>(target_addr);
        assert!(target_balance == 1_000_000, 2); // Balance should remain unchanged

        // Simulate a transaction: target transfers 100,000 tokens to another wallet
        coin::transfer<TestUSDC>(target, funder_addr, 100_000);
        let target_balance = coin::balance<TestUSDC>(target_addr);
        assert!(target_balance == 900_000, 3);

        // Test Case 2: Even after transfer, target's balance (900,000) is still above the threshold (100,000), so auto-topup should not trigger
        auto_topup<TestUSDC>(funder, target_addr, threshold, topup_amount);
        let target_balance = coin::balance<TestUSDC>(target_addr);
        assert!(target_balance == 900_000, 4); // Balance remains the same

        // Simulate another transaction: target transfers 850,000 tokens, reducing the balance below the threshold
        coin::transfer<TestUSDC>(target, funder_addr, 850_000);
        let target_balance = coin::balance<TestUSDC>(target_addr);
        assert!(target_balance == 50_000, 5); // Balance drops below threshold

        // Test Case 3: Now that the balance is below the threshold, auto-topup should trigger and add the top-up amount (1,000,000 tokens)
        auto_topup<TestUSDC>(funder, target_addr, threshold, topup_amount);
        let target_balance = coin::balance<TestUSDC>(target_addr);
        assert!(target_balance == 1_050_000, 6); // Balance should now include the top-up amount
    }
}