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
Start by opening up your Terminal. We're going to use the sui cli to create a new Sui Move Package.

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

Now that we have the bare minimum for a module, let's add some imports to it.

We'll start by importing `UID` from `sui::object`

```rust
use sui::object::{Self, UID};
```

Now we're going to create a few structs, namly our `Bank` object, `OwnerCap` capability and our balances.

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

Now since the admin of this bank is going to charge a fee lets go ahead and add that as well.

```rust
const FEE: u64 = 500;
```

### 1.3 Add Some Functions
This module will have four functions, `init`, `deposit`, `withdraw`, and `claim`

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
Inside of out init function we need to create a new `Bank` object.

Since bank is a Sui Object with a UID that means we need to call

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
So inside of the deposit function we need to get the value of the `token` send in as a argument.

We can do that by calling:
```rust
let value = coin::value(&token);
```

Now we can calculate the deposit value and the admin fee

```rust
let deposit_value = value - (value * FEE / 100);
let admin_fee = value - deposit_value;
```

Now we need to check if the dynamic field for the UserBalance already exists, if it does we can update the balance by joinin the newly deposits coins to the bank. IF not we need to go ahead and add the UserBalance to a dyamic field as well.

```rust
if (df::exists_(&self.id, UserBalance { user: sender })) {
      balance::join(df::borrow_mut<UserBalance, Balance<SUI>>(&mut self.id, UserBalance { user: sender }),
      coin::into_balance(token));
} else {
      df::add(&mut self.id, UserBalance { user: sender }, coin::into_balance(token));
};
```

#### 2.3 Withdraw
The code for withdraw is very simiar to deposit except that is stead of `dynamic_field::add` if the dynamic field doesnt we need to set the balance to zero.

```rust
coin::zero(ctx);
```

#### 2.4 Claim
Last but not least we need to have a public functio that allows the Owner to remove the coins that were paid as a fee

```rust
public fun claim(_: &OwnerCap, self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
    coin::from_balance(df::remove(&mut self.id, AdminBalance {}), ctx)
}  
```

## 3 Finish up
By this point you should have a good scaffold going to finish the remanining code on your own.

You will need to add more `use` includes in your module to pull in various things from the Sui framework.

Good luck and if you have any questions let us know in the discord.
