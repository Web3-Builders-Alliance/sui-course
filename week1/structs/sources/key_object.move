module structs::key_object {

  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;

  // Key Ability 
  // It is the ability to turn a struct into an object, 
  // It can be transfered via a custom function.  
  // It can be transferred to another object or address. Attention - not stored.  
  // It can be shared.  
  // It can store structs with the store ability. 
  //
  // It cannot be transfered with PTBs, it needs a custom transfer function.
  // It cannot be stored inside another Object.
  // It cannot be deleted without a custom function. 
  // It cannot be copied. You must pass a reference or the object. 

  // Think of Soul Bound Tokens. 
  struct KeyObject<T: store> has key {
    // Must have a unique ID to be saved in the database
    id: UID,
    data: T
  }

  public fun new<T: store>(data: T, ctx: &mut TxContext): KeyObject<T> {
    KeyObject {
      id: object::new(ctx),
      data
   }
  }
  
  #[lint_allow(share_owned)]
  public fun share<T: store>(obj: KeyObject<T>) {
    transfer::share_object(obj);
  }

  public fun transfer<T: store>(obj: KeyObject<T>, recipient: address) {
    transfer::transfer(obj, recipient);
  }

  // Object properties cannot only be acessed on the modules they are defined. 
  public fun data_immut<T: store>(obj: &KeyObject<T>): &T {
    &obj.data  
  }

  // Gives Sui rebates as you free space from the storage.  
  // Note how you can have many constraints 
  public fun drop<T: drop + store>(obj: KeyObject<T>) {
    let KeyObject { id, data: _ } = obj;
    object::delete(id);
  }
}