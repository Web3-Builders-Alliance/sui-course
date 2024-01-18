module week1::faucet {
  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::clock::{Self, Clock};
  use sui::table::{Self, Table};
  use sui::coin::{Self, TreasuryCap};
  use sui::tx_context::{Self, TxContext};

  use week1::eth::ETH;
  use week1::usdc::USDC;

  const COOLDOWN: u64 = 300000; // 5 minutes

  const EOnCooldown: u64 = 0;

  struct Faucet has key {
    id: UID,
    eth_cap: TreasuryCap<ETH>,
    usdc_cap: TreasuryCap<USDC>,
    eth_cooldown: Table<address, u64>,
    usdc_cooldown: Table<address, u64>
  }

  #[lint_allow(share_owned)]
  public fun new(
    eth_cap: TreasuryCap<ETH>,
    usdc_cap: TreasuryCap<USDC>,
    ctx: &mut TxContext
  ) {
    transfer::share_object(
      Faucet {
      id: object::new(ctx),
      eth_cap,
      usdc_cap,
      eth_cooldown: table::new(ctx),
      usdc_cooldown: table::new(ctx)
      }
    );
  }

  #[lint_allow(self_transfer)]
  public fun mint_eth(faucet: &mut Faucet, c:&Clock, ctx: &mut TxContext) {
    let timestamp = clock::timestamp_ms(c);
    let sender = tx_context::sender(ctx);

    let last_mint = table::borrow_mut(&mut faucet.eth_cooldown, sender);
    assert!(timestamp >= *last_mint + COOLDOWN, EOnCooldown);

    *last_mint = timestamp;

    transfer::public_transfer(
      coin::mint(&mut faucet.eth_cap, 5_000_000_000, ctx),
      sender
    );
  }

  #[lint_allow(self_transfer)]
  public fun mint_usdc(faucet: &mut Faucet, c:&Clock, ctx: &mut TxContext) {
    let timestamp = clock::timestamp_ms(c);
    let sender = tx_context::sender(ctx);

    let last_mint = table::borrow_mut(&mut faucet.usdc_cooldown, sender);
    assert!(timestamp >= *last_mint + COOLDOWN, EOnCooldown);

    *last_mint = timestamp;
    
    transfer::public_transfer(
      coin::mint(&mut faucet.usdc_cap, 3_000_000_000, ctx),
      sender
    );
  }  
}