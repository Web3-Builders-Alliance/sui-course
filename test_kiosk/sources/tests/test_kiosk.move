#[test_only]
module test_kiosk::test_kiosk {
  use std::option;

  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::transfer_policy::{Self, TransferPolicy};
  use sui::coin::{mint_for_testing, burn_for_testing};
  use sui::kiosk::{Self, Kiosk, KioskOwnerCap, PurchaseCap};

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as ts, next_tx, ctx};

  const OWNER: address = @0x2;
  const ALICE: address = @0x3;
  const BOB: address = @0x4;
  const ARTIST: address = @0x5;

  struct NFT has key, store {
    id: UID
  }

  // 1 - Define Policy
  // 2 - Place
  // 3 - Take
  // 4 - Lock 
  // 5 - List
  // 6 - Delist 
  // 7 - List
  // 8 - Buy
  // 9 - Take Profits
  #[test]
  fun test_case_one() {

    let scenario = ts::begin(@0x1);

    let scenario_mut = &mut scenario;

    // Define Policy
    next_tx(scenario_mut, ARTIST);
    {
      // Define a policy for an item
      let (policy, policy_cap) = transfer_policy::new_for_testing<NFT>(ctx(scenario_mut));

      transfer::public_share_object(policy);
      transfer::public_transfer(policy_cap, ARTIST);
    };

    // 1 - Create a Kiosk
    // 2 - Transfer the Kiosk Owner Cap to the Owner
    // 3 - Share the Kiosk with the network
    next_tx(scenario_mut, OWNER);
    {
      // Create a Kiosk
      let (our_kiosk, cap) = kiosk::new(ctx(scenario_mut));

      transfer::public_share_object(our_kiosk);
      transfer::public_transfer(cap, OWNER);
    };

    let nft = mint(ctx(scenario_mut));
    let nft_id = object::id(&nft);

    // Place -> Take -> Lock -> List
    next_tx(scenario_mut, OWNER);
    {
      let our_kiosk = ts::take_shared<Kiosk>(scenario_mut);
      let cap = ts::take_from_sender<KioskOwnerCap>(scenario_mut);
      let policy = ts::take_shared<TransferPolicy<NFT>>(scenario_mut);

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), false);

      kiosk::place(&mut our_kiosk, &cap, nft);

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), true);
      assert_eq(kiosk::is_locked(&our_kiosk, nft_id), false);

      let taken_nft = kiosk::take<NFT>(&mut our_kiosk, &cap, nft_id);

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), false);

      kiosk::lock(&mut our_kiosk, &cap, &policy, taken_nft);

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), true);
      assert_eq(kiosk::is_locked(&our_kiosk, nft_id), true);
      assert_eq(kiosk::is_listed(&our_kiosk, nft_id), false);

      kiosk::list<NFT>(&mut our_kiosk, &cap, nft_id, 100);

      assert_eq(kiosk::is_listed(&our_kiosk, nft_id), true);

      kiosk::delist<NFT>(&mut our_kiosk, &cap, nft_id);

      assert_eq(kiosk::is_listed(&our_kiosk, nft_id), false);

      kiosk::list<NFT>(&mut our_kiosk, &cap, nft_id, 100);

      assert_eq(kiosk::is_listed(&our_kiosk, nft_id), true);   
      assert_eq(kiosk::is_listed_exclusively(&our_kiosk, nft_id), false);   

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

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), false);

      transfer_policy::confirm_request(&policy, request);

      burn(nft);

      ts::return_shared(our_kiosk);
      ts::return_shared(policy);   
    };

    next_tx(scenario_mut, OWNER);
    {
      let our_kiosk = ts::take_shared<Kiosk>(scenario_mut);
      let cap = ts::take_from_sender<KioskOwnerCap>(scenario_mut);  

      assert_eq(kiosk::profits_amount(&our_kiosk), 100);

      let profit= kiosk::withdraw(&mut our_kiosk, &cap, option::some(100), ctx(scenario_mut));

      assert_eq(kiosk::profits_amount(&our_kiosk), 0);
      assert_eq(burn_for_testing(profit), 100);
      
      ts::return_shared(our_kiosk);
      ts::return_to_sender(scenario_mut, cap);   
    };    
    
    ts::end(scenario);
  }

  // 1 - Place
  // 2 - Exclusive List
  // 3 - Purchase Exclusively
  #[test]
  fun test_case_two() {

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

      transfer::public_share_object(policy);
      transfer::public_share_object(our_kiosk);
      transfer::public_transfer(cap, OWNER);
      transfer::public_transfer(policy_cap, OWNER);
    };

    let nft = mint(ctx(scenario_mut));
    let nft_id = object::id(&nft);

    // Place -> Exclusive List
    next_tx(scenario_mut, OWNER);
    {
      let our_kiosk = ts::take_shared<Kiosk>(scenario_mut);
      let cap = ts::take_from_sender<KioskOwnerCap>(scenario_mut);
      let policy = ts::take_shared<TransferPolicy<NFT>>(scenario_mut);

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), false);

      kiosk::place(&mut our_kiosk, &cap, nft);

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), true);
      assert_eq(kiosk::is_locked(&our_kiosk, nft_id), false);
      assert_eq(kiosk::is_listed(&our_kiosk, nft_id), false);

      let purchase_cap = kiosk::list_with_purchase_cap<NFT>(&mut our_kiosk, &cap, nft_id, 100, ctx(scenario_mut));

      assert_eq(kiosk::is_listed(&our_kiosk, nft_id), true);
      assert_eq(kiosk::is_listed_exclusively(&our_kiosk, nft_id), true);    

      transfer::public_transfer(purchase_cap, BOB);

      ts::return_to_sender(scenario_mut, cap);
      ts::return_shared(our_kiosk);
      ts::return_shared(policy);
    };

    next_tx(scenario_mut, BOB);
    {
      let our_kiosk = ts::take_shared<Kiosk>(scenario_mut);
      let policy = ts::take_shared<TransferPolicy<NFT>>(scenario_mut);   
      let purchase_cap = ts::take_from_sender<PurchaseCap<NFT>>(scenario_mut);

      assert_eq(kiosk::has_item(&our_kiosk, nft_id), true);

      let (nft, request) = kiosk::purchase_with_cap<NFT>(&mut our_kiosk, purchase_cap, mint_for_testing(100, ctx(scenario_mut)));

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