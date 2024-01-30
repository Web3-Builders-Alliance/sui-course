module sui_bank::amm {
  // === Imports ===

  use sui::balance;
  use sui::sui::SUI;
  use sui::coin::{Self, Coin};
  use sui::tx_context::TxContext;

  use sui_bank::bank::{Self, Bank};
  use sui_bank::sui_dollar::{Self, CapWrapper, SUI_DOLLAR};

  // === Constants ===

  const EXCHANGE_RATE: u128 = 40;  

  // === Public-Mutative Functions ===  

  public fun swap_sui(bank: &mut Bank, cap: &mut CapWrapper, coin_in: Coin<SUI>, ctx: &mut TxContext): Coin<SUI_DOLLAR> {
      let sui_dollar_amount = (((coin::value(&coin_in) as u128) * EXCHANGE_RATE / 100) as u64);
      balance::join(bank::balance_mut(bank), coin::into_balance(coin_in));
      sui_dollar::mint(cap, sui_dollar_amount, ctx)
  }

  public fun swap_sui_dollar(bank: &mut Bank, cap: &mut CapWrapper, coin_in: Coin<SUI_DOLLAR>, ctx: &mut TxContext): Coin<SUI> {
    coin::take(
      bank::balance_mut(bank),
      ((((sui_dollar::burn(cap, coin_in) as u128) * 100) / EXCHANGE_RATE) as u64),
      ctx
    )
  }
}