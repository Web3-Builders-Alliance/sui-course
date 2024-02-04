module escrow::owned_escrow {
  // === Imports ===
  
  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::{Self, TxContext};

  // === Structs ===

  struct Escrow<T: store> has key {
    id: UID,
    sender: address,
    recipient: address,
    item: T
  }  

  // === Public-Mutative Functions ===

  public fun new<T: store>(item: T, agent: address, recipient: address, ctx: &mut TxContext) {
    let escrow = Escrow {
      id: object::new(ctx),
      recipient,
      sender: tx_context::sender(ctx),
      item
    };

    transfer::transfer(escrow, agent);
  }  

  public fun transfer_to_recipient<T: store>(self: Escrow<T>) {
    let recipient = self.recipient;
    transfer::transfer(self, recipient);
  } 


  public fun transfer_to_sender<T: store>(self: Escrow<T>) {
    let sender = self.sender;
    transfer::transfer(self, sender);
  } 

  public fun destroy<T: store>(self: Escrow<T>): T {
    let Escrow { id, sender: _, recipient: _, item } = self;

    object::delete(id);

    item
  }

  // === Public-View Functions ===

  public fun sender<T:store>(self: &Escrow<T>): address {
    self.sender
  }

  public fun recipient<T:store>(self: &Escrow<T>): address {
    self.recipient
  }

  public fun item<T:store>(self: &Escrow<T>): &T {
    &self.item
  }   
}