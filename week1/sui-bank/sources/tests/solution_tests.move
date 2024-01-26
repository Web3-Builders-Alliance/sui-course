#[test_only]
module sui_bank::solutions_tests { 

  use sui::test_utils::assert_eq;
  use sui::coin::{mint_for_testing, burn_for_testing};
  use sui::test_scenario::{Self, next_tx, Scenario, ctx};

  use sui_bank::solution::{Self, Bank, OwnerCap};

  const ADMIN: address = @0xBEEF;
  const ALICE: address =  @0x1337;

  #[test]
  fun test_deposit() {
    let scenario = init_bank();
    let scenario_mut = &mut scenario;

    next_tx(scenario_mut, ALICE); 
    {
      let bank = test_scenario::take_shared<Bank>(scenario_mut);

      deposit(&mut bank, 100, scenario_mut);

      assert_eq(solution::admin_balance(&bank), 5);
      assert_eq(solution::user_balance(&bank, ALICE), 95);

      test_scenario::return_shared(bank);
    };

    next_tx(scenario_mut, ALICE); 
    {
      let bank = test_scenario::take_shared<Bank>(scenario_mut);

      deposit(&mut bank, 50, scenario_mut);

      assert_eq(solution::admin_balance(&bank), 7);
      assert_eq(solution::user_balance(&bank, ALICE), 143);

      test_scenario::return_shared(bank);
    };

    test_scenario::end(scenario);
  }


  #[test]
  fun test_withdraw() {
    let scenario = init_bank();
    let scenario_mut = &mut scenario;

    next_tx(scenario_mut, ALICE); 
    {
      let bank = test_scenario::take_shared<Bank>(scenario_mut);
      
      let coin_out = solution::withdraw(&mut bank, ctx(scenario_mut));

      assert_eq(burn_for_testing(coin_out), 0);

      test_scenario::return_shared(bank);
    };

    next_tx(scenario_mut, ALICE); 
    {
      let bank = test_scenario::take_shared<Bank>(scenario_mut);

      deposit(&mut bank, 100, scenario_mut);
      
      assert_eq(solution::user_balance(&bank, ALICE), 95);
      
      let coin_out = solution::withdraw(&mut bank, ctx(scenario_mut));

      assert_eq(burn_for_testing(coin_out), 95);
      assert_eq(solution::user_balance(&bank, ALICE), 0);

      test_scenario::return_shared(bank);
    };

    test_scenario::end(scenario);
  }  

  #[test]
  fun test_partial_withdraw() {
    let scenario = init_bank();
    let scenario_mut = &mut scenario;

    next_tx(scenario_mut, ALICE); 
    {
      let bank = test_scenario::take_shared<Bank>(scenario_mut);

      deposit(&mut bank, 100, scenario_mut);
      
      assert_eq(solution::user_balance(&bank, ALICE), 95);
      
      let coin_out = solution::partial_withdraw(&mut bank, 10, ctx(scenario_mut));

      assert_eq(burn_for_testing(coin_out), 10);
      assert_eq(solution::user_balance(&bank, ALICE), 85);

      test_scenario::return_shared(bank);
    };

    test_scenario::end(scenario);
  }  

  #[test]
  fun test_claim() {
    let scenario = init_bank();
    let scenario_mut = &mut scenario;

    next_tx(scenario_mut, ADMIN); 
    {
      let cap = test_scenario::take_from_sender<OwnerCap>(scenario_mut);
      let bank = test_scenario::take_shared<Bank>(scenario_mut);

      deposit(&mut bank, 100, scenario_mut);
      
      assert_eq(solution::admin_balance(&bank), 5);
      
      let coin_out = solution::claim(&cap,&mut bank, ctx(scenario_mut));

      assert_eq(burn_for_testing(coin_out), 5);
      assert_eq(solution::admin_balance(&bank), 0);

      test_scenario::return_to_sender(scenario_mut, cap);
      test_scenario::return_shared(bank);
    };

    test_scenario::end(scenario);
  }
  
  #[test]
  #[expected_failure(abort_code = solution::ENotEnoughBalance)]
  fun test_partial_withdraw_not_enough_balance() {
    let scenario = init_bank();
    let scenario_mut = &mut scenario;

    next_tx(scenario_mut, ALICE); 
    {
      let bank = test_scenario::take_shared<Bank>(scenario_mut);

      deposit(&mut bank, 100, scenario_mut);
      
      assert_eq(solution::user_balance(&bank, ALICE), 95);
      
      let coin_out = solution::partial_withdraw(&mut bank, 1001, ctx(scenario_mut));

      burn_for_testing(coin_out);

      test_scenario::return_shared(bank);
    };

    test_scenario::end(scenario);    
  }

  // helpers

  fun init_bank(): Scenario {
   let scenario = test_scenario::begin(ADMIN);
    let scenario_mut = &mut scenario;

    next_tx(scenario_mut, ADMIN);
    {
      solution::init_for_testing(ctx(scenario_mut));
    };

    scenario
  }

  fun deposit(bank: &mut Bank, value: u64, scenario_mut: &mut Scenario) {
    solution::deposit(bank, mint_for_testing(value, ctx(scenario_mut)), ctx(scenario_mut));
  }
}