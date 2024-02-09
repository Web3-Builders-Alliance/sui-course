#[test_only]
module test_kiosk::test_solution {
  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::coin::mint_for_testing;
  use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
  use sui::transfer_policy::{Self, TransferPolicy};

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as ts, next_tx, ctx};

  use test_kiosk::treasury;

  const OWNER: address = @0x2;
  const ALICE: address = @0x3;

  struct NFT has key, store {
    id: UID
  }

  #[test]
  fun test_case_one() {

    let scenario = ts::begin(@0x1);

    let scenario_mut = &mut scenario;

    // 1 - Create a Kiosk
    // 2 - Transfer the Kiosk Owner Cap to the Owner
    // 3 - Share the Kiosk with the network
    next_tx(scenario_mut, OWNER);
    {
      // Create a Kiosk
      let (our_kiosk, cap) = kiosk::new(ctx(scenario_mut));

      // Define a policy for an item
      let (policy, policy_cap) = transfer_policy::new_for_testing<NFT>(ctx(scenario_mut));

      treasury::add_rule(&mut policy, &policy_cap);

      transfer::public_share_object(policy);
      transfer::public_share_object(our_kiosk);
      transfer::public_transfer(cap, OWNER);
      transfer::public_transfer(policy_cap, OWNER);
    };

    let nft = mint(ctx(scenario_mut));
    let nft_id = object::id(&nft);

    // Place and List
    next_tx(scenario_mut, OWNER);
    {
      let our_kiosk = ts::take_shared<Kiosk>(scenario_mut);
      let cap = ts::take_from_sender<KioskOwnerCap>(scenario_mut);
      let policy = ts::take_shared<TransferPolicy<NFT>>(scenario_mut);

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), false);
      assert_eq(kiosk::is_listed(&our_kiosk, nft_id), false);

      kiosk::place_and_list(&mut our_kiosk, &cap, nft, 100);  

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), true);
      assert_eq(kiosk::is_listed(&our_kiosk, nft_id), true);

      ts::return_to_sender(scenario_mut, cap);
      ts::return_shared(our_kiosk);
      ts::return_shared(policy);
    };

    next_tx(scenario_mut, ALICE);
    {
      let our_kiosk = ts::take_shared<Kiosk>(scenario_mut);
      let policy = ts::take_shared<TransferPolicy<NFT>>(scenario_mut);   

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), true);

      let (nft, request) = kiosk::purchase<NFT>(&mut our_kiosk, nft_id, mint_for_testing(100, ctx(scenario_mut)));

      treasury::add_receipt(&mut request, mint_for_testing(10, ctx(scenario_mut)));

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), false);

      transfer_policy::confirm_request(&policy, request);

      burn(nft);

      ts::return_shared(our_kiosk);
      ts::return_shared(policy);   
    };
    
    ts::end(scenario);
  }  

  fun mint(ctx: &mut TxContext): NFT {
    NFT {
      id: object::new(ctx)
    }
  }

  fun burn(self: NFT) {
    let NFT { id } = self;
    object::delete(id);
  }  
}


#[test_only]
module test_kiosk::treasury {

  use sui::transfer;
  use sui::sui::SUI;
  use sui::coin::{Self, Coin};
  use sui::transfer_policy::{Self, TransferPolicyCap, TransferPolicy, TransferRequest};

  struct TreasuryWitness has drop {}

  struct Config has store, drop {
    amount: u64,
    
  }
  
  const ERoyaltyValueIsWrong: u64 = 0;

  const TREASURY: address = @0x10;

  public fun add_rule<T>(policy: &mut TransferPolicy<T>, cap: &TransferPolicyCap<T>) {
    transfer_policy::add_rule(TreasuryWitness {}, policy, cap, Config { amount: 10 });
  }

  public fun add_receipt<T>(request: &mut TransferRequest<T>, royalty: Coin<SUI>) {
    assert!(coin::value(&royalty) >= 10, ERoyaltyValueIsWrong);
    transfer::public_transfer(royalty, TREASURY);
    transfer_policy::add_receipt(TreasuryWitness {}, request);
  }

  public fun amount(config: &Config): u64 {
    config.amount
  }
}