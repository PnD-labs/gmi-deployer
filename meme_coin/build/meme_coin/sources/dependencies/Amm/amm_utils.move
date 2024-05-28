module amm::amm_utils{
    
    use amm::amm_math;
    use std::debug;
    
    
    public fun compute_amount_out(
        amount_in: u64,
        input_reserve: u64,
        output_reserve: u64,
        fee_denominator: u64,
        fee_numerator: u64
    ): u64 {
        let swap_amount = calculate_swap_amount_after_fee(amount_in,fee_denominator,fee_numerator);
        let new_input_reserve = input_reserve + swap_amount;
        let k  = (input_reserve as u128) * (output_reserve as u128);
        output_reserve  - (k / (new_input_reserve as u128)as u64 )
    }

    public fun calculate_swap_amount_after_fee(amount_in:u64,fee_denominator:u64,fee_numerator:u64):u64{
        
        let fee  = amm_math::safe_mul_div_u64(amount_in,fee_numerator,fee_denominator);
        let result = amount_in - fee;
        // debug::print(&result);
        result
    }
}

#[test_only]
module amm::test_amm_utils {
    use amm::amm_utils;
    use amm::amm_math;
    // use std::debug;
    #[test]
    // Test function for compute_amount_out
    public fun test_compute_amount_out() {
        // Test case 1
        let amount_in = 1000;
        let input_reserve = 1000;
        let output_reserve = 1000;
        let fee_denominator = 1000;
        let fee_numerator = 3;
        let expected_output = 500; // This value needs to be calculated based on your specific logic
        let actual_output = amm_utils::compute_amount_out(amount_in, input_reserve, output_reserve, fee_denominator, fee_numerator);
        assert!(actual_output == expected_output, 0); // Replace 0 with a specific error code if needed
    }
        // Add more test cases as needed
    
    #[test]
    // Test function for calculate_swap_amount_after_fee
    public fun test_calculate_swap_amount_after_fee() {
        // Test case 1
        let fee_denominator = 1000;
        let fee_numerator = 3;
        let amount_in = 1000;
        let expected_output = 997; // This value needs to be calculated based on your specific logic
        let actual_output = amm_utils::calculate_swap_amount_after_fee( amount_in,fee_denominator, fee_numerator);
        // debug::print(&actual_output);
        assert!(actual_output == expected_output, 0); // Replace 1 with a specific error code if needed

        // Add more test cases as needed
    }


}

