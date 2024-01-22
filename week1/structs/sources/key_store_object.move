module structs::key_store_object {

  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;

  use structs::key_object::{Self, KeyObject};

  // Key + Store Ability 
  // It is the ability to turn a struct into an object, 
  // It can be transfered without a custom transfer function. Can you se PTBs.  
  // It can be transferred to another object or address. 
  // It can be shared.  
  // It can be stored inside another object.
  //
  // It cannot be deleted without a custom function. 
  // It cannot be copied. You must pass a reference or the object. 

  struct KeyStoreObject has key, store {
    // Must have a unique ID to be saved in the database
    id: UID
  }

  public fun new(ctx: &mut TxContext): KeyStoreObject {
    KeyStoreObject {
      id: object::new(ctx)
    }
  }

  #[lint_allow(share_owned, custom_state_change)]
  public fun share(obj: KeyStoreObject) {
    transfer::share_object(obj);
  }

  // We can store inside the key_object 
  // Notice how we need to use public
  public fun store(obj: KeyStoreObject, ctx: &mut TxContext): KeyObject<KeyStoreObject> {
    key_object::new(obj, ctx)
  }

  // Gives Sui rebates as you free space from the storage.  
  public fun destroy(obj: KeyStoreObject) {
    let KeyStoreObject { id } = obj;
    object::delete(id);
  }
}