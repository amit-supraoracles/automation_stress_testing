module demo2::supra_oracle_storage {
    use std::signer;
    use aptos_std::table;
    use aptos_std::vector;

    use supra_framework::object;

    /// User Requesting for invalid pair or subscription
    const EINVALID_PAIR: u64 = 1;

    /// Defined Oracle seeds that are used for creating resources
    const SEED_ORACLE: vector<u8> = b"MockOracleHolder";

    /// Unauthorized access
    const UNAUTHORIZED_ACCESS: u64 = 1;
    /// Address is already whitelisted
    const EALREADY_WHITELISTED: u64 = 2;
    /// Address is not whitelisted
    const EADDRESS_NOT_WHITELISTED: u64 = 3;

    #[resource_group_member(group = supra_framework::object::ObjectGroup)]
    struct OracleHolderObjectController has key {
        transfer_ref: object::TransferRef,
        extend_ref: object::ExtendRef,
    }

    #[resource_group_member(group = supra_framework::object::ObjectGroup)]
    /// Manage price feeds of respective pairs
    struct MockOracleHolder has key, store {
        feeds: table::Table<u32, Entry>,
    }

    /// Pair data value structure
    struct Entry has drop, store {
        value: u128,
        decimal: u16,
        timestamp: u64,
        round: u64,
    }

    /// Return type of the price that we are given to customer
    struct Price has store, drop {
        pair: u32,
        value: u128,
        decimal: u16,
        timestamp: u64,
        round: u64
    }

    struct WhitelistAddresses has key {
        whitelist: vector<address>
    }

    /// Its Initial function which will be executed automatically while deployed packages
    fun init_module(owner_signer: &signer) acquires WhitelistAddresses {
        let cons_ref = object::create_named_object(owner_signer, SEED_ORACLE);
        let object_signer = object::generate_signer(&cons_ref);
        move_to(&object_signer, OracleHolderObjectController {
            transfer_ref: object::generate_transfer_ref(&cons_ref),
            extend_ref: object::generate_extend_ref(&cons_ref)
        });
        move_to(&object_signer, MockOracleHolder { feeds: table::new() });

        // whitelist there own address
        add_whitelist(owner_signer, signer::address_of(owner_signer));
    }

    #[test_only]
    public fun initialize_for_test(owner_signer: &signer) acquires WhitelistAddresses {
        init_module(owner_signer);
    }

    /// Automation task that will fetch the oracle price feed data and store in the our storage
    public entry fun mock_price_feed(
        owner_signer: &signer,
        pair_id: u32,
        value: u128,
        decimal: u16,
        timestamp: u64,
        round: u64
    ) acquires MockOracleHolder, WhitelistAddresses {
        assert!(is_whitelisted(signer::address_of(owner_signer)), UNAUTHORIZED_ACCESS);

        let oracle_holder = borrow_global_mut<MockOracleHolder>(get_oracle_holder_address());
        table::upsert(&mut oracle_holder.feeds, pair_id, Entry { value, decimal, timestamp, round });
    }

    /// Automation task that will fetch the oracle price feed data and store in the our storage in bulk
    public entry fun mock_price_feed_bulk(
        owner_signer: &signer,
        pair_ids: vector<u32>,
        values: vector<u128>,
        decimals: vector<u16>,
        timestamps: vector<u64>,
        rounds: vector<u64>
    ) acquires MockOracleHolder, WhitelistAddresses {
        assert!(is_whitelisted(signer::address_of(owner_signer)), UNAUTHORIZED_ACCESS);

        let oracle_holder = borrow_global_mut<MockOracleHolder>(get_oracle_holder_address());

        let pairs_length = vector::length(&pair_ids);
        assert!(pairs_length == vector::length(&values), 1);
        assert!(pairs_length == vector::length(&decimals), 1);
        assert!(pairs_length == vector::length(&timestamps), 1);
        assert!(pairs_length == vector::length(&rounds), 1);

        while (!vector::is_empty(&pair_ids)) {
            let pair_id = vector::pop_back(&mut pair_ids);
            let value = vector::pop_back(&mut values);
            let decimal = vector::pop_back(&mut decimals);
            let timestamp = vector::pop_back(&mut timestamps);
            let round = vector::pop_back(&mut rounds);
            table::upsert(&mut oracle_holder.feeds, pair_id, Entry { value, decimal, timestamp, round });
        };
    }

    /// Function which checks that is pair index is exist in OracleHolder
    public fun is_pair_exist(oracle_holder: &MockOracleHolder, pair_index: u32): bool {
        table::contains(&oracle_holder.feeds, pair_index)
    }

    /// Add address to whitelist
    public entry fun add_whitelist(owner_signer: &signer, whitelist_address: address) acquires WhitelistAddresses {
        assert!(signer::address_of(owner_signer) == @demo2, UNAUTHORIZED_ACCESS);
        create_whitelist_storage(owner_signer);

        assert!(!is_whitelisted(whitelist_address), EALREADY_WHITELISTED);
        let whitelist = borrow_global_mut<WhitelistAddresses>(@demo2);
        vector::push_back(&mut whitelist.whitelist, whitelist_address);
    }

    /// Remove address from whitelist
    public entry fun remove_whitelist(owner_signer: &signer, whitelist_address: address) acquires WhitelistAddresses {
        assert!(signer::address_of(owner_signer) == @demo2, UNAUTHORIZED_ACCESS);

        assert!(is_whitelisted(whitelist_address), EADDRESS_NOT_WHITELISTED);
        let whitelist = borrow_global_mut<WhitelistAddresses>(@demo2);
        vector::remove_value(&mut whitelist.whitelist, &whitelist_address);
    }

    public fun is_whitelisted(user_address: address): bool acquires WhitelistAddresses {
        let whitelist = borrow_global<WhitelistAddresses>(@demo2);
        vector::contains(&whitelist.whitelist, &user_address)
    }

    fun create_whitelist_storage(owner_signer: &signer) {
        if (!exists<WhitelistAddresses>(@demo2)) {
            move_to(owner_signer, WhitelistAddresses { whitelist: vector[] })
        }
    }

    #[view]
    /// It will return MockOracleHolder resource address
    public fun get_oracle_holder_address(): address {
        object::create_object_address(&@demo2, SEED_ORACLE)
    }

    #[view]
    /// External view function
    /// It will return the priceFeedData value for that particular tradingPair
    public fun get_price(oracle_holder: address, pair: u32): (u128, u16, u64, u64) acquires MockOracleHolder {
        let oracle_holder = borrow_global<MockOracleHolder>(oracle_holder);
        assert!(is_pair_exist(oracle_holder, pair), EINVALID_PAIR);
        let feed = table::borrow(&oracle_holder.feeds, pair);
        (feed.value, feed.decimal, feed.timestamp, feed.round)
    }

    #[view]
    /// External view function
    /// It will return the priceFeedData value for that multiple tradingPair
    /// If any of the pairs do not exist in the OracleHolder, an empty vector will be returned for that pair.
    /// If a client requests 10 pairs but only 8 pairs exist, only the available 8 pairs' price data will be returned.
    public fun get_prices(oracle_holder: address, pairs: vector<u32>): vector<Price> acquires MockOracleHolder {
        let oracle_holder = borrow_global<MockOracleHolder>(oracle_holder);
        let prices: vector<Price> = vector::empty();

        vector::for_each_reverse(pairs, |pair| {
            if (is_pair_exist(oracle_holder, pair)) {
                let feed = table::borrow(&oracle_holder.feeds, pair);
                vector::push_back(
                    &mut prices,
                    Price { pair, value: feed.value, decimal: feed.decimal, timestamp: feed.timestamp, round: feed.round }
                );
            };
        });
        prices
    }

    /// External public function
    /// It will return the extracted price value for the Price struct
    public fun extract_price(price: &Price): (u32, u128, u16, u64, u64) {
        (price.pair, price.value, price.decimal, price.timestamp, price.round)
    }
}
