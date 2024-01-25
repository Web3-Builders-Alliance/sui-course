module sui_bank::exercise_tests { 

  use sui::test_utils::assert_eq;
  use sui::coin::{mint_for_testing};
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use sui_bank::solution::{Self, Bank};

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

  // Good luck
}