# Kiosk dApp

In this lesson, we are going to: 
1. Create a Kiosk
2. Cover the core functionalities of Kiosk
3. Look at some of the Policies for Kiosk

## 0. Clone Repo

Clone down the latest version of sui-course and open the test_kiosk.move file. Let's cover some of the basics of what is going on in this file.

## 1. Create a new Kiosk

To get started, we're going to look at creating a transfer policy and a new kiosk.

#### 1.1 Define a policy

To use Kiosk, we should always define a transfer policy. You can see an example of how to do that below.

```rust
 let (policy, policy_cap) = transfer_policy::new_for_testing<NFT>(ctx(scenario_mut));
```
With our transfer policy, we can now create a new kiosk!

```rust
let (our_kiosk, cap) = kiosk::new(ctx(scenario_mut));

```
The next step would be to publicly share the policy and kiosk object and to transfer the kiosk owner cap and policy cap to our kiosk owner.

```rust
transfer::public_share_object(policy);
transfer::public_share_object(our_kiosk);transfer::public_transfer(cap, OWNER);
transfer::public_transfer(policy_cap, OWNER);
```
Alright, so we have looked at how to create a kiosk, so let's cover how to use it.

#### 1.2 Placing an item

Once we have a kiosk, the first thing we need to do is place an item, Since this is a unit test, we must use it to get the objects we want to use.

The most common thing people place in a kiosk right now are NFTs, so let's just mock one up for our examples.

```rust  
let nft = mint(ctx(scenario_mut));
let nft_id = object::id(&nft);
```

Finally, let's place an object. To do that, we call the place method inside the Kiosk module, and we pass it our Kiosk object, owner cap, and NFT. This means that only the owner of a kiosk can actually place an item in it. We will use some assertions to verify the expected behavior.

```rust
kiosk::place(&mut our_kiosk, &cap, nft);
assert_eq(kiosk::has_item(&our_kiosk, nft_id), true);
assert_eq(kiosk::is_locked(&our_kiosk, nft_id), false);
```


### 1.3 Taking an item

Since we have placed an item, let's take it back. Again,  just like with a place, only the owner is allowed to take an item from the kiosk.

```rust
let taken_nft = kiosk::take<NFT>(&mut our_kiosk, &cap, nft_id);

assert_eq(kiosk::has_item(&our_kiosk, nft_id), false);
```

### 1.4 Locking an item

So now that we have tried place and take, let's use lock. Lock will place an item into the kiosk and create a lock for it so that it. To use a lock, we must provide a policy so that the item locked can be listed and sold. Without this policy, the item could get locked forever.

```rust
kiosk::lock(&mut our_kiosk, &cap, &policy, taken_nft);
assert_eq(kiosk::has_item(&our_kiosk, nft_id), true);
assert_eq(kiosk::is_locked(&our_kiosk, nft_id), true);
assert_eq(kiosk::is_listed(&our_kiosk, nft_id), false);
```

### 1.5 Listing an item

In order for an item in a kiosk to be sold, it must first be listed. To list an item, we can do something like below. So let's call the list and pass it out: kiosk object, owner cap, object ID, and the price for which we want to list this item. One thing to note is that Kiosk items can only be bought and sold using Sui; it currently doesn't allow the use of custom coins.

```rust
kiosk::list<NFT>(&mut our_kiosk, &cap, nft_id, 100);

assert_eq(kiosk::is_listed(&our_kiosk, nft_id), true);
```

### 1.6 Delisting an item

Just like we can list an item, we can delist one. This is useful if the price you listed it for is no longer acceptable or if you just decide to keep the item in question.

```rust
kiosk::delist<NFT>(&mut our_kiosk, &cap, nft_id);

assert_eq(kiosk::is_listed(&our_kiosk, nft_id), false);
```

### 1.7 Purchasing an item

To purchase an item, it must be listed in the Kiosk, and to do that, we just call it the purchase method.

```rust
let (nft, request) = kiosk::purchase<NFT>(&mut our_kiosk, nft_id, mint_for_testing(100, ctx(scenario_mut)));
```

purchase returns the item and the policy request, so after we purchase the item, we must confirm the policy request.

```rust
transfer_policy::confirm_request(&policy, request);
```

### 1.8 Exclusive list

You can add a purchase capability when listing if you want to restrict who can buy the item. Once you list with a purchase cap, you can then transfer that cap to the user you want to give access to purchasing this item.

```rust
let purchase_cap = kiosk::list_with_purchase_cap<NFT>(&mut our_kiosk, &cap, nft_id, 100, ctx(scenario_mut));
transfer::public_transfer(purchase_cap, BOB);
```

### 1.9 Exclusive purchase

If you have listed an item with a purchase cap, then you need to call the method purchase_with_cap to purchase it.

```rust
let (nft, request) = kiosk::purchase_with_cap<NFT>(&mut our_kiosk, purchase_cap, mint_for_testing(100, ctx(scenario_mut)));
```

Just like with the normal purchase method, you need to confirm the request with the transfer policy.

```rust
transfer_policy::confirm_request(&policy, request);
```

### 1.10 Check our Kiosk profits and Withdraw

Once someone has purchased an object from our kiosk, we should have profits. To check, we can run

```rust
kiosk::profits_amount(&our_kiosk)
```

If profits are available, then we can withdraw them.

```rust
let profit= kiosk::withdraw(&mut our_kiosk, &cap, option::some(100), ctx(scenario_mut));
```

### 1.11 Transfer policy rules

We can add custom rules to our transfer policy to enforce behavior. To add a rule, just call

```rust
    transfer_policy::add_rule(...)
```

To verify that the rule has been satisfied, we can use add_receipt; this is the proof that the rule has been completed as expected.

```rust
transfer_policy::add_receipt(...)
```

That covers our quick overview of some of the core features of Kiosk. Try thinking about how you could use Kiosk in your capstone.

### Challenge
We want you to add a royalty policy to the test_kiosk. move the file inside the week3 folder of sui-course. To do so, you will need to add a rule and verify it with the added receipt.