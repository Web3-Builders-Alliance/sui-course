module escrow::shared_escrow {
  // === Imports ===

  use std::option::{Self, Option};
  
  use sui::transfer;
  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};

  // === Errors ===

  const EUnauthorizedSender: u64 = 0;
  const ECannotRemoveItemAfterValidation: u64 = 1;
  const EUnauthorizedAgent: u64 = 2;
  const ECannotValidateAnEmptyEscrow: u64 = 3;
  const EUnauthorizedRecipient: u64 = 4;
  const ECannotReceiveInvalidEscrow: u64 = 5;
  const EEscrowMustBeEmpty: u64 = 6;
  const EOnlyAgentCanDestroyAnEscrow: u64 = 7;

  // === Constants ===

  // === Structs ===

  struct Recipient {}

  struct Sender {}

  struct Agent {}

  struct Access<phantom T> has key {
    id: UID
  }

  struct Escrow<T: store> has key {
    id: UID,
    sender: ID,
    recipient: ID,
    agent: ID,
    validated: bool,
    item: Option<T>
  }  

  // === Public-Mutative Functions ===

  public fun new<T: store>(ctx: &mut TxContext): (Access<Agent>, Access<Recipient>, Access<Sender>) {
    let recipient = Access<Recipient> {
      id: object::new(ctx)
    };


    let sender = Access<Sender> {
      id: object::new(ctx)
    };

    let agent = Access<Agent> {
      id: object::new(ctx)
    };

    transfer::share_object(
      Escrow<T> {
        id: object::new(ctx),
        item: option::none(),
        sender: object::id(&sender),
        agent: object::id(&agent),
        validated: false,
        recipient: object::id(&recipient)
      }
    );

    (agent, recipient, sender)
  }  

  public fun new_and_transfer<T: store>(_sender: address, _recipient: address, ctx: &mut TxContext) {
    let (agent, recipient, sender) = new<T>(ctx);
    transfer::transfer(agent, tx_context::sender(ctx));
    transfer::transfer(recipient, _recipient);
    transfer::transfer(sender, _sender);
  } 

  public fun add<T: store>(self: &mut Escrow<T>, cap: &Access<Sender>, item: T) {
    assert!(object::id(cap) == self.sender, EUnauthorizedSender);

    option::fill(&mut self.item, item);
  }

  public fun remove<T: store>(self: &mut Escrow<T>, cap: &Access<Sender>): T {
    assert!(object::id(cap) == self.sender, EUnauthorizedSender);
    assert!(!self.validated, ECannotRemoveItemAfterValidation);

    option::extract(&mut self.item)
  }

  public fun validate<T: store>(self: &mut Escrow<T>, cap: &Access<Agent>) {
    assert!(object::id(cap) == self.agent, EUnauthorizedAgent);
    assert!(option::is_some(&self.item), ECannotValidateAnEmptyEscrow);

    self.validated = true;
  }    

  public fun receive<T: store>(self: &mut Escrow<T>, cap: Access<Recipient>): T {
    assert!(object::id(&cap) == self.recipient, EUnauthorizedRecipient);
    assert!(self.validated, ECannotReceiveInvalidEscrow);

    destroy_access(cap);
    option::extract(&mut self.item)
  }

  public fun destroy_empty_escrow<T: store>(self: Escrow<T>, cap: &Access<Agent>) {
    assert!(option::is_none(&self.item), EEscrowMustBeEmpty);
    assert!(object::id(cap) == self.agent, EOnlyAgentCanDestroyAnEscrow);

    let Escrow { id, sender: _, recipient: _, agent: _, item, validated: _ } = self;

    option::destroy_none(item);
    object::delete(id);
  }

  public fun destroy_access<T>(cap: Access<T>) {
    let Access { id } = cap;
    object::delete(id);  
  }

  // === Public-View Functions ===

  public fun sender<T:store>(self: &Escrow<T>): ID {
    self.sender
  }

  public fun recipient<T:store>(self: &Escrow<T>): ID {
    self.recipient
  }

  public fun agent<T: store>(self: &Escrow<T>): ID {
    self.agent
  }  

  public fun validated<T:store>(self: &Escrow<T>): bool {
    self.validated
  }  

  public fun item<T:store>(self: &Escrow<T>): &Option<T> {
    &self.item
  }   
}