module structs::event {

  use sui::tx_context::TxContext;

  use structs::key_object::{Self, KeyObject};

  /*
  * It is compacted data, it isn ot an object. 
  * It can be copied 
  * It can be dropped. 
  * It can be stored inside an object.  
  *
  * It cannot be transferred.  
  */
  struct Event has copy, drop, store {}

  public fun drop() {
    Event {};
    // We do not need to return, share or anything.  
    // We can just drop it. It gets deleted. 
  }

  // We can store inside the key_object 
  // Notice how we need to use public
  public fun store(ctx: &mut TxContext): KeyObject<Event> {
    key_object::new(Event {}, ctx)
  }  

  public fun copy_() {
    let event1 = Event {};
    // event 2 is a copy of event1. Not a pointer.
    let _event2 = event1;
  }
}