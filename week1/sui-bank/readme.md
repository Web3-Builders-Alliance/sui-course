# Bank dApp

In this lesson, we are going to:

1. Create a new Sui Move module
2. Using Capabilities
3. Storing coins in a vault
4. Charging a admin fee for depositing coins

Prerequisites:

1. Have Sui CLI Installed
2. Have VSCode Installed
3. sui-move-analyzer extension for VSCode is not required but it is very useful.

Let's get into it!

## 1. Create a new Package

To get started, we're going to create a new move package and an create a module for our package.

#### 1.1 Setting up

Begin by opening your terminal. We will use the Sui CLI to create a new Sui Move Package.

```sh
sui move new bank && cd bank
touch sources/bank.move
```

Now open up the package directory in VSCode.

#### 1.2 Create a new module

Open up `bank.move` and lets start building this package.

```ts
module bank::bank {
    /*...*/
}
```

After establishing the module's basic structure, let's include some necessary imports.

We'll start by importing `UID` from `sui::object`

```rust
use sui::object::{Self, UID};
```

Next, let's define several structs, including our `Bank` object, `OwnerCap` capability, and various balances.

```rust
  struct Bank has key {
    id: UID
  }

  struct OwnerCap has key, store {
    id: UID
  }

  struct UserBalance has copy, drop, store { user: address }
  struct AdminBalance has copy, drop, store {}
```

Since the admin of this bank will charge a fee, let's define that fee. Note that the fee is a `u128`, not `u64`.

```rust
const FEE: u128 = 5;
```

### 1.3 Add Some Functions

Now, let's define four functions for this module: `init`, `deposit`, `withdraw`, and `claim`.

```rust
fun init(ctx: &mut TxContext) {
    /*...*/
}

public fun deposit(self: &mut Bank, token: Coin<SUI>, ctx: &mut TxContext) {
    /*...*/
}

public fun withdraw(self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
    /*...*/
}

public fun claim(_: &OwnerCap, self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
    /*...*/
}
```

## 2. Challenge Requirements

Now that we have a basic layout of our module lets go over some of the things you will need to complete for this challenge.

#### 2.1 Init

Within our `init` function, we must create a new `Bank `object.

Since bank is a Sui Object with a UID that means we need to call object::new with the transaction context.

```rust
let bank = Bank { id: object::new(ctx) };
```

After that we need to add a `AdminBalance` to a dynamic_field that will reference the bank.id as a object and a value of zero sui. You can use `balance::zero<SUI>()` for the value.

The built in dynamic field add function has a signature like so:

```rust
    /// Adds a dynamic field to the object `object: &mut UID` at field specified by `name: Name`.
    /// Aborts with `EFieldAlreadyExists` if the object already has that field with that name.
    public fun add<Name: copy + drop + store, Value: store>
```

Inside of your module add the line below

```rust
dynamic_field::add(.., .., ..);
```

Now fill in the various arguments with the correct data based on what you read above.

Now inside of the same init function we need to call two methods belonging to the transfer module. first is share_object, our goal is to share the bank object and then we need to transfer the `OwnerCap` to the sender.

```rust
transfer::share_object(..)
```

and

```rust
transfer::transfer(..)
```

Once that is done we can move on to Deposit

#### 2.2 Deposit

In the deposit function, retrieve the value of the `token` passed as an argument.


We can do that by calling:

```rust
let value = coin::value(&token);
```

Now we can calculate the deposit value and the admin fee

```rust
// To avoid overflows, we cast the value to u128 when multiplying then cast it back to u64.
let deposit_value = value - (((value as u128) * FEE / 100) as u64);
let admin_fee = value - deposit_value;
```

Now we need to check if the dynamic field for the UserBalance already exists, if it does we can update the balance by joining the newly deposited coins to the bank. If not, we need to go ahead and add a new UserBalance dynamic field.

```rust
if (df::exists_(&self.id, UserBalance { user: sender })) {
      balance::join(df::borrow_mut<UserBalance, Balance<SUI>>(&mut self.id, UserBalance { user: sender }),
      coin::into_balance(token));
} else {
      df::add(&mut self.id, UserBalance { user: sender }, coin::into_balance(token));
};
```

#### 2.3 Withdraw

The code for withdraw is very similar to deposit except that instead of `dynamic_field::add`, we will use `dynamic_field::remove`. Please note that the withdraw function does not throw if the user has no balance. It returns a coin with a value of zero.

```rust
coin::zero(ctx);
```

#### 2.4 Claim

Last but not least we need to have a public function that allows the Owner to remove the coins that were paid as a fee.

```rust
public fun claim(_: &OwnerCap, self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
    coin::from_balance(df::remove(&mut self.id, AdminBalance {}), ctx)
}
```

#### 2.5 Bonus: Balance

We challenge the cadets to add a getter function that allows anyone to know how much balance a user has in the bank.

```rust
public fun balance(self: &mut Bank, user: address): u64 {
    // Good Luck
}
```

## 3 Finish up

By this point you should have a good scaffold going to finish the remaining code on your own.

You will need to add more `use` includes in your module to pull in various things from the Sui framework.

Please refer to the [Sui Framework](https://github.com/MystenLabs/sui/tree/main/crates/sui-framework/packages/sui-framework/sources), while you are BUIDLin. It is the best way to quickly improve your Sui Move skills.

Good luck and if you have any questions let us know in the discord.
