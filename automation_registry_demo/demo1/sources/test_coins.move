module demo1::coins {
    use std::string::utf8;
    use supra_framework::coin::{Self, MintCapability, BurnCapability};
    use supra_framework::supra_account;

    struct TestBTC {}

    struct TestUSDC {}

    /// Storing mint/burn capabilities for coins under user account.
    struct Caps<phantom CoinType> has key {
        mint: MintCapability<CoinType>,
        burn: BurnCapability<CoinType>,
    }

    /// Initialize module at the time of contract deployment
    fun init_module(token_admin: &signer) {
        register_coins(token_admin);
    }

    /// Initializes All above coins.
    public entry fun register_coins(token_admin: &signer) {
        let (usdc_b, usdc_f, usdc_m) =
            coin::initialize<TestUSDC>(token_admin,
                utf8(b"Test USDC Coin"), utf8(b"TUSDC"), 6, true);

        let (btc_b, btc_f, btc_m) =
            coin::initialize<TestBTC>(token_admin,
                utf8(b"Test Bitcoin"), utf8(b"TBTC"), 8, true);

        coin::destroy_freeze_cap(usdc_f);
        coin::destroy_freeze_cap(btc_f);

        move_to(token_admin, Caps<TestUSDC> { mint: usdc_m, burn: usdc_b });
        move_to(token_admin, Caps<TestBTC> { mint: btc_m, burn: btc_b });
    }

    /// Mints new coin `CoinType` on account `acc_addr`.
    public entry fun mint_coin<CoinType>(token_admin: &signer, acc_addr: address, amount: u64) acquires Caps {
        let token_admin_addr = supra_framework::signer::address_of(token_admin);

        // if they have mint capability then can mint it
        let caps = borrow_global<Caps<CoinType>>(token_admin_addr);
        let coins = coin::mint<CoinType>(amount, &caps.mint);
        supra_account::deposit_coins<CoinType>(acc_addr, coins);
    }

}
