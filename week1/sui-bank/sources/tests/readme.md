# Testing our Bank

In this lesson, we are going to:

1. Learn about Moves' Unit Testing Framework
2. Test Annotations
3. How to Test modules that use Coins
4. Use assertions to validate behavior.

## 0. Why do we test?

In the old days of programming debuggers were all the rage, you would set breakpoints and then step into/over code and view the behavior to make sure things were behaving correctly but as time went on this was seen as insuffient to creating reliable code. So in 1997 the first unit test framework was created and it slowly became the norm.

The great thing about tests is that as a program evolves you have a fast and efficient way of verifying that the new code does not break the code that has been written prior! The fact is the stakes are high when writing programs and it should be treated as such, in classical programming you can have memory leaks which could cause the program to crash unexpectidly, crash the operating system or freeze it. While thats already bad when it comes to on-chain programs it gets even worse because we can have `Money Leaks`. None of us want to cause a user to lose money because of a money leak so it is imperritive we test our code and test it well!

## 1. Create a tests folder

To get started, we're going to create a `tests` folder inside of our package.

#### 1.1 Creating our test module.

To start unit testing we will need to create a test module, test modules are no diffrent than normal modules except they use test annotations to ensure the code is not uploaded to the Sui Network and also so that the code is only ran during the testing phase.

Lets create the module below.

```rust
module bank::bank_tests {
    /*...*/
}
```

#### 1.2 Adding our imports

For this test module we will be using a some built in test utilities provided by Sui. Lets go ahead and include them and then we will talk about them individually. Remember like all imports in Move they must be added INSIDE of the module. We will also add two consts that will represent the addresses of our Admin and User.

```rust
module bank::bank_tests {
    use sui::test_utils::assert_eq;
    use sui::coin::{mint_for_testing, burn_for_testing};
    use sui::test_scenario as ts;

    use bank::bank::{Self, Bank};

    const ADMIN: address = @0xBEEF;
    const ALICE: address =  @0x1337;

    /*...*/
}
```

#### 1.3 Test Utils

Sui's test_utils module contains a few helpful functions that you will be using throughout your Sui development journey. lets take a look.

```rust
    //asserts that two values are equal.
    public fun assert_eq<T: drop>(t1: T, t2: T)
    //asserts that two values are equal via reference.
    public fun assert_ref_eq<T>(t1: &T, t2: &T)
    //print information during tests
    public fun print(str: vector<u8>)
    //destroy a value for tests
    public native fun destroy<T>(x: T)
    //create a one time witness for tests
    public native fun create_one_time_witness<T: drop>(): T;
```

The above functions are avaliable only during testing and the way that Sui ensures that is the use of the
`#[test_only]` annotation which is placed above the test_utils module like so. You can think of annotations as metadata or attributes that provide additional information to the Move compiler, influencing the behavior of the code or affecting how it is processed.

```rust
#[test_only]
module sui::test_utils {
    /*...*/
}
```

There are two more annotations we will be using in our tests, `#[test]` and `#[expect_failure]`. Can you guess what these annotations do? if you guessed that `#[test]` is used to define a unit test and `#[expect_failure]` tells the compiler that the unit test should fail you'd be right!

#### 1.4 Test Senarios

The Sui test_senario module is much larger than test_utils so we wont go over every function included in it but we will highlight a few of them.

`begin`, `end`, `next_tx`, `take_from_sender`, `return_to_sender`, `take_shared`, `return_shared`

`begin` is used to start a new multi-transaction test scenario while `end` is used to end it. Since I come from a C++ background I tend to think of `begin` and `end` similar to `new` and `delete`, meaning that if you call `begin` you must call `end`!

`next_tx` advanced the scenario to the next transaction, this must be called before we can use any of the `take`, `return` functions.

`take_from_sender` will take a owned object from the sender so it can be used inside of a transaction.

`return_to_sender` will return that owned object to the sender, if you try to return a object to a diffrent address than it was taken from the test will abort.

`take_shared` & `return_shared` are just like the two above but instead of dealing with owned objects they deal with shared objects.

if you want to see the entire module you can view it on [github](https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/packages/sui-framework/sources/test/test_scenario.move)

Enough chatting lets build our first test case!

### 2. Lets Init!

Our bank app has four functions `init`, `deposit`, `withdraw`, and `claim` so first we will write a test for `init`. Since we are placing our tests outside of our `bank` module and inside of their own `bank_test` module we need to add a single `#[test_only]` function inside of `bank`.

Scroll to the very bottom of `bank.move` and add the following line:

```rust
#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}
```

This line will allow our `bank_test` module to call the banks `init` but as you can see we use the `#[test_only]` annotation so when we build and upload the package to the testnet it will not include this function.

Next, inside of our `bank_tests.move` lets create a new function

```rust
fun init_test_helper() : ts::Scenario{
    let scenario_val = ts::begin(ADMIN);
    let scenario = &mut scenario_val;
    {
        init_for_testing(ts::ctx(scenario));
    };
    scenario_val
}
```

Since we will be using init in every test case extracting it out into it's own function helps to keep that functionality encapsulated so we can read and maintain our test code with ease.

Now lets crate a test case that will use this `init_test_helper` function.

```rust
  #[test]
  fun test_deposit() {
      let scenario_val = init_test_helper();
      let scenario = &mut scenario_val;

      /*...*/

      ts::end(scenario_val);
  }
```

The above test doesn't do much at this point, but it does make sure our init function is correctly working which is the first step to testing the rest of the module!

#### 2.1 Deposit some SUI

So we have our first test case, now lets deposit some sui. To do this we will create two more helper functions so we stay true to the [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself) principle.

```rust
  fun deposit_test_helper(scenario: &mut ts::Scenario, addr:address, amount:u64) {
    ts::next_tx(scenario, id);
    {
        /*...*/
    };
  }
```

This helper have 3 arguments, the test scenario, the ID(address) of the individual calling it and the amount to deposit. You may wonder how will we deposit Sui if we don't have any? we will get to that but for now lets focus on `next_tx`. You will notice the `next_tx` call and under it a code block, when `next_tx` is called a new transaction has started and the code block under it helps us visualize the actions taken during that transaction.

Now lets dive in further:

```rust
  fun deposit_test_helper(scenario: &mut ts::Scenario, addr:address, amount:u64, fee_percent:u8) {
    ts::next_tx(scenario, addr);
    {
      let bank = ts::take_shared<Bank>(scenario);
      bank::deposit(&mut bank, mint_for_testing(amount, ts::ctx(scenario)), ts::ctx(scenario));

      let (user_amount, admin_amount) = calculate_fee_helper(amount, fee_percent);

      assert_eq(bank::user_balance(&bank, addr), user_amount);
      assert_eq(bank::admin_balance(&bank), admin_amount);

      ts::return_shared(bank);
    };
  }
```

so lets go over each step:

Bank is a shared object so to get it we must use `take_shared`, but like we talked about above since we `take` something we must also `return` it, we do that with `return_shared`.

Next we use another helper function, `calculate_fee_helper` to caluclate the admin_amount and the user_amount and we assert it is what we expect. I will leave the exersise of creating this helper to you!

We call the `bank::deposit` entry function and we use the helper function provided by the Coin module to `mint_for_testing` this mints the required `Coin<SUI>` that we will deposit.

Now that our helper is finished lets add it to the test case.

```rust
  #[test]
  fun test_deposit() {
      let scenario_val = init_test_helper();
      let scenario = &mut scenario_val;

      deposit_test_helper(scenario, ALICE, 100, 5);

      ts::end(scenario_val);
  }
```

Nice! we now have a completed test case for depositing into our bank, if you run `sui move test` it should pass!

The next step would be to do a reverse test, lets pass in the wrong fee_percent and make sure the test fails.

```rust
    #[test]
    #[expected_failure]
  fun test_deposit_fail() {
      let scenario_val = init_test_helper();
      let scenario = &mut scenario_val;

      deposit_test_helper(scenario, ALICE, 100, 6);

      ts::end(scenario_val);
  }
```

## 3. Challenge Time!

Ok now the challenge from here on is to finish the testing, you must create a `withdraw_test`, and a `claim_test`. Don't just test for success you should test for failure as well for better coverage!

Good luck and if you have any questions let us know in the discord.
