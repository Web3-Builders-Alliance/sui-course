module sui_bank::solution {
  use sui::sui::SUI;
  use sui::transfer;
  use sui::coin::{Self, Coin};
  use sui::object::{Self, UID};
  use sui::dynamic_field as df;
  use sui::balance::{Self, Balance};
  use sui::tx_context::{Self, TxContext};

  struct Bank has key {
    id: UID
  }

  struct OwnerCap has key, store {
    id: UID
  }

  struct UserBalance has copy, drop, store { user: address }
  struct AdminBalance has copy, drop, store {}

  const FEE: u128 = 5;

  const ENotEnoughBalance: u64 = 0;

  fun init(ctx: &mut TxContext) {
    let bank = Bank { id: object::new(ctx) };

    df::add(&mut bank.id, AdminBalance {}, balance::zero<SUI>());

    transfer::share_object(
      bank
    );

    transfer::transfer(OwnerCap { id: object::new(ctx) }, tx_context::sender(ctx));
  }

  public fun user_balance(self: &Bank, user: address): u64 {
    let key = UserBalance { user };
    if (df::exists_(&self.id, key)) {
      balance::value(df::borrow<UserBalance, Balance<SUI>>(&self.id, key))
    } else {
      0
    }
  }

  public fun admin_balance(self: &Bank): u64 {
    balance::value(df::borrow<AdminBalance, Balance<SUI>>(&self.id, AdminBalance {}))
  }  
  
  public fun deposit(self: &mut Bank, token: Coin<SUI>, ctx: &mut TxContext) {
    let value = coin::value(&token);
    let deposit_value = value - (((value as u128) * FEE / 100) as u64);
    let admin_fee = value - deposit_value;

    let admin_coin = coin::split(&mut token, admin_fee, ctx);
    balance::join(df::borrow_mut<AdminBalance, Balance<SUI>>(&mut self.id, AdminBalance {}), coin::into_balance(admin_coin));

    let sender = tx_context::sender(ctx);

    if (df::exists_(&self.id, UserBalance { user: sender })) {
      balance::join(df::borrow_mut<UserBalance, Balance<SUI>>(&mut self.id, UserBalance { user: sender }), coin::into_balance(token));
    } else {
      df::add(&mut self.id, UserBalance { user: sender }, coin::into_balance(token));
    };
  }

  public fun withdraw(self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
    let sender = tx_context::sender(ctx);

    if (df::exists_(&self.id, UserBalance { user: sender })) {
      coin::from_balance(df::remove(&mut self.id, UserBalance { user: sender }), ctx)
    } else {
       coin::zero(ctx)
    }
  }

  public fun partial_withdraw(self: &mut Bank, value: u64, ctx: &mut TxContext): Coin<SUI> {
    let balance_mut = df::borrow_mut<UserBalance, Balance<SUI>>(&mut self.id, UserBalance { user: tx_context::sender(ctx) });

    assert!(balance::value(balance_mut) >= value, ENotEnoughBalance);

    coin::take(balance_mut, value, ctx)
  }

  public fun claim(_: &OwnerCap, self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
    let balance_mut = df::borrow_mut<AdminBalance, Balance<SUI>>(&mut self.id, AdminBalance {});
    let total_admin_bal = balance::value(balance_mut);
    coin::take(balance_mut, total_admin_bal, ctx)
  }   

  // ENTRY FNS
  
  entry fun entry_deposit(self: &mut Bank, token: Coin<SUI>, ctx: &mut TxContext) {
    deposit(self, token, ctx);
  } 

  entry fun withdraw_and_keep(self: &mut Bank, ctx: &mut TxContext) {
    transfer::public_transfer(withdraw(self, ctx), tx_context::sender(ctx));
  } 

  entry fun partial_withdraw_and_keep(self: &mut Bank, value: u64, ctx: &mut TxContext) {
    transfer::public_transfer(partial_withdraw(self, value, ctx), tx_context::sender(ctx));
  } 

  entry fun claim_and_keep(_: &OwnerCap, self: &mut Bank, ctx: &mut TxContext) {
    transfer::public_transfer(claim(_, self, ctx), tx_context::sender(ctx));
  }      

  // TEST ONLY
  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
  }
}