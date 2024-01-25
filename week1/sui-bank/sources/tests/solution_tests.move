module sui_bank::solution_tests { 

  use sui::test_utils::assert_eq;
  use sui::coin::{mint_for_testing, burn_for_testing};
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use sui_bank::solution::{Self, Bank, OwnerCap};

  const ADMIN: address = @0xBEEF;
  const ALICE: address =  @0x1337;

  #[test]
  fun test_deposit() {
    let scenario = test::begin(@0x1);
    let test = &mut scenario;

    next_tx(test, ADMIN);
    {
      solution::init_for_testing(ctx(test));
    };

    next_tx(test, ALICE); 
    {
      let bank = test::take_shared<Bank>(test);

      solution::deposit(&mut bank, mint_for_testing(100, ctx(test)), ctx(test));

      assert_eq(solution::admin_balance(&bank), 5);
      assert_eq(solution::user_balance(&bank, ALICE), 95);

      test::return_shared(bank);
    };

    next_tx(test, ALICE); 
    {
      let bank = test::take_shared<Bank>(test);

      solution::deposit(&mut bank, mint_for_testing(50, ctx(test)), ctx(test));

      assert_eq(solution::admin_balance(&bank), 7);
      assert_eq(solution::user_balance(&bank, ALICE), 143);

      test::return_shared(bank);
    };

    test::end(scenario);
  }


  #[test]
  fun test_withdraw() {
    let scenario = test::begin(@0x1);
    let test = &mut scenario;

    next_tx(test, ADMIN);
    {
      solution::init_for_testing(ctx(test));
    };

    next_tx(test, ALICE); 
    {
      let bank = test::take_shared<Bank>(test);
      
      let coin_out = solution::withdraw(&mut bank, ctx(test));

      assert_eq(burn_for_testing(coin_out), 0);

      test::return_shared(bank);
    };

    next_tx(test, ALICE); 
    {
      let bank = test::take_shared<Bank>(test);

      solution::deposit(&mut bank, mint_for_testing(100, ctx(test)), ctx(test));
      
      assert_eq(solution::user_balance(&bank, ALICE), 95);
      
      let coin_out = solution::withdraw(&mut bank, ctx(test));

      assert_eq(burn_for_testing(coin_out), 95);
      assert_eq(solution::user_balance(&bank, ALICE), 0);

      test::return_shared(bank);
    };

    test::end(scenario);
  }  

  #[test]
  fun test_partial_withdraw() {
    let scenario = test::begin(@0x1);
    let test = &mut scenario;

    next_tx(test, ADMIN);
    {
      solution::init_for_testing(ctx(test));
    };

    next_tx(test, ALICE); 
    {
      let bank = test::take_shared<Bank>(test);

      solution::deposit(&mut bank, mint_for_testing(100, ctx(test)), ctx(test));
      
      assert_eq(solution::user_balance(&bank, ALICE), 95);
      
      let coin_out = solution::partial_withdraw(&mut bank, 10, ctx(test));

      assert_eq(burn_for_testing(coin_out), 10);
      assert_eq(solution::user_balance(&bank, ALICE), 85);

      test::return_shared(bank);
    };

    test::end(scenario);
  }  

  #[test]
  fun test_claim() {
    let scenario = test::begin(@0x1);
    let test = &mut scenario;

    next_tx(test, ADMIN);
    {
      solution::init_for_testing(ctx(test));
    };

    next_tx(test, ADMIN); 
    {
      let cap = test::take_from_sender<OwnerCap>(test);
      let bank = test::take_shared<Bank>(test);

      solution::deposit(&mut bank, mint_for_testing(100, ctx(test)), ctx(test));
      
      assert_eq(solution::admin_balance(&bank), 5);
      
      let coin_out = solution::claim(&cap,&mut bank, ctx(test));

      assert_eq(burn_for_testing(coin_out), 5);
      assert_eq(solution::admin_balance(&bank), 0);

      test::return_to_sender(test, cap);
      test::return_shared(bank);
    };

    test::end(scenario);
  }
  
  #[test]
  #[expected_failure(abort_code = solution::ENotEnoughBalance)]
  fun test_partial_withdraw_not_enough_balance() {
    let scenario = test::begin(@0x1);
    let test = &mut scenario;

    next_tx(test, ADMIN);
    {
      solution::init_for_testing(ctx(test));
    };

    next_tx(test, ALICE); 
    {
      let bank = test::take_shared<Bank>(test);

      solution::deposit(&mut bank, mint_for_testing(100, ctx(test)), ctx(test));
      
      assert_eq(solution::user_balance(&bank, ALICE), 95);
      
      let coin_out = solution::partial_withdraw(&mut bank, 1001, ctx(test));

      burn_for_testing(coin_out);

      test::return_shared(bank);
    };

    test::end(scenario);    
  }
}