module amm::amm_config{
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::balance::{Self, Balance};
    use sui::sui::{SUI};

    public struct ConfigAdminCap has key {
        id: UID
    }

    public struct Config has key {
        id: UID,
        mint_total_supply: u64,
        mint_decimal: u8,
        mint_fee: u64,
        swap_fee_numerator: u64,
        swap_fee_denominator: u64,
        protocol_fee_numerator: u64,
        protocol_fee_denominator:u64,
        protocol_fee_switch:bool,
        minimum_swap_amount:u64,
    }

    fun init(ctx: &mut TxContext) {
        let admin_cap = ConfigAdminCap { id: object::new(ctx) };
        transfer::transfer(admin_cap, sender(ctx));
        transfer::share_object(Config {
            id: object::new(ctx),
            mint_decimal: 18,
            mint_total_supply: 1_000_000_000_000_000_000,
            mint_fee: 1000,
            swap_fee_numerator: 3, // 0.3% = 3 / 1000
            swap_fee_denominator: 1000,
            protocol_fee_numerator: 1, // 0% = 0 / 1
            protocol_fee_denominator: 1,
            protocol_fee_switch:false,
            minimum_swap_amount:1000,
        });
    }
    
    // Getters
    public fun get_mint_fee(config: &Config): u64 {
        config.mint_fee
    }

    public fun get_mint_total_supply(config: &Config): u64 {
        config.mint_total_supply
    }

    public fun get_mint_decimal(config: &Config): u8 {
        config.mint_decimal
    }

    public fun get_swap_fee(config: &Config): (u64, u64) {
        (config.swap_fee_numerator, config.swap_fee_denominator)
    }

    public fun get_protocol_fee(config: &Config): (u64, u64) {
        (config.protocol_fee_numerator, config.protocol_fee_denominator)
    }
    public fun get_protocol_fee_switch(config: &Config): bool {
        config.protocol_fee_switch
    }
    public fun get_minimum_swap_amount(config: &Config): u64 {
        config.minimum_swap_amount
    }
    // Set
    entry fun set_mint_total_supply(_:&ConfigAdminCap, config: &mut Config, new_total_supply: u64) {
        config.mint_total_supply = new_total_supply;
    }

    entry fun set_mint_fee(_:&ConfigAdminCap, config: &mut Config, new_fee: u64) {
        config.mint_fee = new_fee;
    }

    entry fun set_mint_decimal(_:&ConfigAdminCap, config: &mut Config, new_decimal: u8) {
        config.mint_decimal = new_decimal;
    }

    entry fun set_swap_fee(_:&ConfigAdminCap, config: &mut Config, new_numerator: u64, new_denominator: u64) {
        config.swap_fee_numerator = new_numerator;
        config.swap_fee_denominator = new_denominator;
    }

    entry fun set_protocol_fee(_:&ConfigAdminCap, config: &mut Config, new_numerator: u64, new_denominator: u64) {
        config.protocol_fee_numerator = new_numerator;
        config.protocol_fee_denominator = new_denominator;
    }
    entry fun set_protocol_fee_switch(_:&ConfigAdminCap, config: &mut Config, new_switch: bool) {
        config.protocol_fee_switch = new_switch;
    }
    entry fun set_minimum_swap_amount(_:&ConfigAdminCap, config: &mut Config, new_minimum_swap_amount: u64) {
        config.minimum_swap_amount = new_minimum_swap_amount;
    }
}
