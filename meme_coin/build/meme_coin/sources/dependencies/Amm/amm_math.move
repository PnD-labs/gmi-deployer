module amm::amm_math{
    // use std::debug;
    const EInvalidDivParam:u64 = 0;
    public fun safe_mul_u64(x: u64, y: u64): u64 {
        let result = ((x as u128) * (y as u128) as u64);
        // debug::print(&result);
        result
        
    }
     public fun safe_add_u64(a: u64, b: u64): u64 {
        let sum = ((a as u128) + (b as u128)) as u64;
        sum
    }
    
    public fun safe_div_u128_to_u64(a: u128, b: u128): u64 {
        assert!(b > 0, EInvalidDivParam);
        let quotient = (a / b) as u64;
        quotient
    }
    public fun safe_mul_div_u64(x: u64, y: u64, z: u64): u64 {
        ((x as u128) * (y as u128) / (z as u128) as u64)
    }

}
