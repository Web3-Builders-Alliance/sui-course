module structs::store_object {

  use sui::tx_context::TxContext;

  use structs::key_object::{Self, KeyObject};

  // Store Ability 
  // It is NOT an object.
  // It can ONLY be stored inside an object.  
  //
  // It cannot be transferred. 
  // It cannot be deleted without a custom function. 
  // It cannot be copied. You must pass a reference. 

  // They are just compacted data. 
  struct StoreObject<T> has store {
    // Must have a unique ID to be saved in the database
    data: T
  }

  // Note how numbers have the store ability. 
  public fun new(ctx: &mut TxContext): KeyObject<StoreObject<u64>> {
    key_object::new(StoreObject { data: 1 }, ctx)
  }

  public fun data_immut(obj: &KeyObject<StoreObject<u64>>): &u64 {
    // we cannot obj.data.  
    // The key_object module needs to expose a getter  
    // We can do .data on the StoreObject. 
    &key_object::data_immut(obj).data
  }
}