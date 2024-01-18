module amm::admin {

  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::{Self, TxContext};
  
  struct Admin has key {
    id: UID
  }   

  #[allow(unused_function)]
  fun init(ctx: &mut TxContext) {
    transfer::transfer(
      Admin { id: object:: new(ctx )},
      tx_context::sender(ctx)
    );
  }
}