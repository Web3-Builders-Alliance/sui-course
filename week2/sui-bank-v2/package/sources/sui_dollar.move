module sui_bank::sui_dollar {
  // === Imports ===

  use std::option;

  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::coin::{Self, Coin, TreasuryCap};

  // === Friends ===

  friend sui_bank::amm;
  friend sui_bank::lending;

  // === Structs ===  

  struct SUI_DOLLAR has drop {}

  struct CapWrapper has key {
    id: UID,
    cap: TreasuryCap<SUI_DOLLAR>
  }

  // === Init ===  

  #[lint_allow(share_owned)]
  fun init(witness: SUI_DOLLAR, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<SUI_DOLLAR>(
            witness, 
            9, 
            b"SUID",
            b"Sui Dollar", 
            b"Stable coin issued by Sui Bank", 
            option::none(), 
            ctx
        );

      transfer::share_object(CapWrapper { id: object::new(ctx), cap: treasury_cap });
      transfer::public_share_object(metadata);
  }

  // === Public-Mutative Functions ===  

  public fun burn(cap: &mut CapWrapper, coin_in: Coin<SUI_DOLLAR>): u64 {
    coin::burn(&mut cap.cap, coin_in)
  }

  // === Public-Friend Functions ===  

  public(friend) fun mint(cap: &mut CapWrapper, value: u64, ctx: &mut TxContext): Coin<SUI_DOLLAR> {
    coin::mint(&mut cap.cap, value, ctx)
  }

  // === Test Functions ===  

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(SUI_DOLLAR {}, ctx);
  }
}