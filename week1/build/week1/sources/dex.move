module week1::dex {
  use std::type_name::{Self, TypeName};

  use sui::transfer;
  use sui::coin::{Self, Coin};
  use sui::object::{Self, UID};
  use sui::dynamic_field as df;
  use sui::tx_context::TxContext;
  use sui::balance::{Self, Balance};

  use week1::curve;
  use week1::utils;
  use week1::admin::Admin;

  const EWrongOrder: u64 = 0;
  const ENoZeroSeedLiquidity: u64 = 1;
  const ENoZeroSwaps: u64 = 2;

  struct Pool has key {
    id: UID,
  } 

  struct LpCoin<phantom CoinX, phantom CoinY> {}

  struct State<phantom CoinX, phantom CoinY> has store {
    balance_x: Balance<CoinX>,
    balance_y: Balance<CoinY>
  }

  #[lint_allow(share_owned)]
  public fun new<CoinX, CoinY>(
    _: &Admin,
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    ctx: &mut TxContext
  ) {
    assert!(utils::are_coins_ordered<CoinX, CoinY>(), EWrongOrder);
    assert!(coin::value(&coin_x) != 0 && coin::value(&coin_y) != 0, ENoZeroSeedLiquidity);

    let pool = Pool {
      id: object::new(ctx)
    };

    df::add(&mut pool.id, get_key<CoinX, CoinY>(), State { 
      balance_x: coin::into_balance(coin_x),
      balance_y: coin::into_balance(coin_y)
     });

    transfer::share_object(pool);
  }

  public fun swap<CoinIn, CoinOut>(
    pool: &mut Pool,
    coin_in: Coin<CoinIn>,
    ctx: &mut TxContext
  ): Coin<CoinOut> {
    assert!(coin::value(&coin_in) != 0, ENoZeroSwaps);

    if (utils::is_coin_x<CoinIn, CoinOut>()) 
      swap_x_impl<CoinIn, CoinOut>(pool, coin_in, ctx)
    else 
      swap_y_impl<CoinOut, CoinIn>(pool, coin_in,  ctx)
  }

  fun swap_x_impl<CoinX, CoinY>(
    pool: &mut Pool,
    coin_in: Coin<CoinX>,
    ctx: &mut TxContext
  ): Coin<CoinY> {
     let state = df::borrow_mut<TypeName, State<CoinX,CoinY>>(&mut pool.id, get_key<CoinX, CoinY>());  

     let amount_out =  curve::get_amount_out(coin::value(&coin_in), balance::value(&state.balance_x), balance::value(&state.balance_y));

     balance::join(&mut state.balance_x, coin::into_balance(coin_in));

     coin::take(&mut state.balance_y, amount_out, ctx)
  }

  fun swap_y_impl<CoinX, CoinY>(
    pool: &mut Pool,
    coin_in: Coin<CoinY>,
    ctx: &mut TxContext
  ): Coin<CoinX> {
     let state = df::borrow_mut<TypeName, State<CoinX,CoinY>>(&mut pool.id, get_key<CoinX, CoinY>());  


     let amount_out =  curve::get_amount_out(coin::value(&coin_in), balance::value(&state.balance_y), balance::value(&state.balance_x));

     balance::join(&mut state.balance_y, coin::into_balance(coin_in));

     coin::take(&mut state.balance_x, amount_out, ctx)
  }  

  fun get_key<CoinX, CoinY>(): TypeName {
    type_name::get<LpCoin<CoinX, CoinY>>()
  }
}