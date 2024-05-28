module amm::amm_swap {
    use sui::object::{Self, UID};
    use sui::coin::{Self, Coin,CoinMetadata,TreasuryCap};
    use sui::sui::{SUI};
    
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self,Balance};
    use sui::event::{Self};
    use sui::pay::{Self};
    use sui::clock::{Self, Clock};
 
    
    use amm::amm_config::{Self,Config};
    use amm::amm_math::{Self};
    use amm::amm_utils::{Self};
 
    //@@gmi pool is don't have lp token
    public struct Pool<phantom MemeCoin> has key {
        id: UID,
        reserve_meme: Balance<MemeCoin>,
        reserve_sui: Balance<SUI>,
        //Locked if pool is $69K or more.
        lock:bool,
    }

    //@@ Event
    public struct CreatePoolEvent has copy,drop{
        account:address,
        pool_id:ID,
        treasury_id:ID,
        metadata_id:ID,
        reserve_meme:u64,
        reserve_sui:u64,
    }


    public struct SwapEvent has copy,drop{
        account:address,
        pool_id:ID,
        meme_in_amount:u64,
        meme_out_amount:u64,
        sui_in_amount:u64,
        sui_out_amount:u64,
        reserve_meme:u64,
        reserve_sui:u64,
    }
    
    const INIT_MEME_COIN_AMOUNT:u64 = 100_000_000_000_000_000;


    const ECoinInsufficient: u64 = 0;
    const EInvalidInitialAmount:u64 = 1;
    // Entry function to mint a new coin and initialize a liquidity pool
    entry fun create_pool<MemeCoin>(
        treasury:&TreasuryCap<MemeCoin>,
        metadata:&CoinMetadata<MemeCoin>,
        meme_coin:Coin<MemeCoin>,
        sui_token: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(meme_coin.value() == INIT_MEME_COIN_AMOUNT, EInvalidInitialAmount);
        //@@balance check                   
       let pool = Pool<MemeCoin>{
            id: object::new(ctx),
            reserve_meme: coin::into_balance(meme_coin),
            reserve_sui: coin::into_balance(sui_token),
            lock:false,
        };
        let pool_id = object::id(&pool);
        let metadata_id = object::id(metadata);
        let treasury_id = object::id(treasury);
        let event = CreatePoolEvent{
            account: tx_context::sender(ctx),
            pool_id,
            metadata_id,
            treasury_id,
            reserve_meme:pool.reserve_meme.value(),
            reserve_sui:pool.reserve_sui.value(),
        };
        transfer::share_object(pool);
        event::emit(event);
    }

  

    entry public fun sell_meme_coin<MemeCoin>(pool: &mut Pool<MemeCoin>, config: &Config, meme_coin: Coin<MemeCoin>, ctx: &mut TxContext) {
        
        let swap_amount = meme_coin.value();
        let (reserve_meme,reserve_sui) = pool.get_reserves();
        let (swap_fee_numerator,swap_fee_denominator) = amm_config::get_swap_fee(config);
    
        assert!(swap_amount > config.get_minimum_swap_amount(), ECoinInsufficient);
        
        let sui_coin_amount = amm_utils::compute_amount_out(swap_amount,reserve_meme,reserve_sui, swap_fee_denominator,swap_fee_numerator);
        
        let sui_coin = coin::from_balance(pool.reserve_sui.split(sui_coin_amount), ctx);
        
        pool.reserve_meme.join(coin::into_balance(meme_coin));
        pay::keep(sui_coin, ctx);
        event::emit(SwapEvent{
            account: tx_context::sender(ctx),
            pool_id: object::id(pool),
            meme_in_amount:swap_amount,
            meme_out_amount:0,
            sui_in_amount:0,
            sui_out_amount:sui_coin_amount,
            reserve_meme,
            reserve_sui
        })
   
    }


    entry public fun buy_meme_coin<MemeCoin>(pool: &mut Pool<MemeCoin>, config: &Config, sui_coin: Coin<SUI>, ctx:&mut TxContext) {
        
        let sui_coin_amount = sui_coin.value();
        let (reserve_meme,reserve_sui) = pool.get_reserves();
        let (swap_fee_numerator,swap_fee_denominator) = amm_config::get_swap_fee(config);


        assert!(sui_coin_amount > config.get_minimum_swap_amount(), ECoinInsufficient);
        
        let meme_coin_amount =  amm_utils::compute_amount_out(sui_coin_amount,reserve_sui,reserve_meme, swap_fee_denominator,swap_fee_numerator);
        
        let meme_coin = coin::from_balance(pool.reserve_meme.split(meme_coin_amount), ctx);
        pool.reserve_sui.join(coin::into_balance(sui_coin));
        pay::keep(meme_coin, ctx);
        event::emit(SwapEvent{
            account: tx_context::sender(ctx),
            pool_id: object::id(pool),
            meme_in_amount:0,
            meme_out_amount:meme_coin_amount,
            sui_in_amount:sui_coin_amount,
            sui_out_amount:0,
            reserve_meme,
            reserve_sui,
        })
    }
    
    public fun get_reserves<MemeCoin>(pool: &Pool<MemeCoin>) : (u64,u64) {
        let reserve_meme = balance::value(&pool.reserve_meme);
        let reserve_sui = balance::value(&pool.reserve_sui);
        (reserve_meme,reserve_sui)
    }

}
