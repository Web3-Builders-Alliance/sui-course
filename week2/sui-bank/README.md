# Patterns

### Object wrapping

```rust
  struct CapWrapper has key {
    id: UID,
    cap: TreasuryCap<SUI_DOLLAR>
  }
```

It allows us to add access control to shared objects by wrapping them inside an object.

### Access control via capabilities and not via an `address`

```rust
  struct Bank has key {
    id: UID,
    balance: Balance<SUI>,
    admin_balance: Balance<SUI>,
  }

  struct Account has key, store {
    id: UID,
    user: address,
    debt: u64,
    deposit: u64
  }
```

We do store the user balance and debt inside an owned object that can be held by the user of another protocol. The owner of the `Account` object has the custody of the funds.

### Destroy functions

```rust
  public fun destroy_empty_account(account: Account) {
    let Account { id, debt: _, deposit, user: _ } = account;
    assert!(deposit == 0, EAccountMustBeEmpty);
    object::delete(id);
  }
```

The Sui blockchain gives Sui rebates when objects are deleted as it frees up storage slots. It is best practice to provide means for objects to be destroyed. Do keep in mind that you should ensure that the objects being deleted are empty to prevent loss of funds.

## Challenges

- Write a two swap functions with the signature below:

```rust
  public fun swap_sui(self: &mut Bank, acc: &mut Account, coin_in: Coin<SUI>, ctx: &mut TxContext): Coin<SUI_DOLLAR> {
    abort(0)
  }

  public fun swap_sui_dollar(self: &mut Bank, acc: &mut Account, coin_in: Coin<SUI_DOLLAR>, ctx: &mut TxContext): Coin<SUI> {
    abort(0)
  }
```

- Replace SUI with your custom Coin and add a faucet!
