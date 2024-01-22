module functions::interface {

  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::types::is_one_time_witness;

  use functions::two::two_impl;

  struct Object has key, store {
    id: UID 
  }

  // Must have the module name in Caps. 
  struct INTERFACE has drop {}

  // It runs once per deployment 
  // Does not run on upgrades 
  // It receives the One Time Witness as the first argument if defined by the user  
  // It is used to run initial data or create unique objects using the witness. 
  fun init(otw: INTERFACE, _ctx: &mut TxContext) {
    assert!(is_one_time_witness(&otw), 0);
  }

  public fun new(ctx: &mut TxContext): Object {
    Object {
      id: object::new(ctx)
    }
  }

  // Can not be called with the return of other functions in a PTB.  
  // Can only return values with the drop ability.  
  // unsigned integers have copy, drop, store abilities.  
  entry public fun two(): u64 {
    two_impl()
  }

  // Can be called by this module, other modules and from the frontend.  
  public fun one(): u64 {
    one_impl()
  }

  // Public functions without the entry keyword can accept other functions returns 
  // We can call new() -> id() -> transfer()
  public fun id(self: Object): Object {
    self
  }

  // Can only be called inside this module
  fun one_impl(): u64 {
    1
  }
}