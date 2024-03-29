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

  // === Structs ===

  struct Recipient {}

  struct Sender {}

  struct Agent {}

  struct Access<phantom T> has key, store {
    id: UID,
    escrow: ID
  }

  struct Escrow<T: store> has key {
    id: UID,
    validated: bool,
    item: Option<T>
  }  

  // === Public-Mutative Functions ===

  public fun new<T: store>(ctx: &mut TxContext): (Access<Agent>, Access<Recipient>, Access<Sender>) {

    let escrow = Escrow<T> {
        id: object::new(ctx),
        item: option::none(),
        validated: false,
      };

    let escrow_id = object::id(&escrow);

    transfer::share_object(escrow);

    let recipient = Access<Recipient> {
      id: object::new(ctx),
      escrow: escrow_id
    };


    let sender = Access<Sender> {
      id: object::new(ctx),
      escrow: escrow_id
    };

    let agent = Access<Agent> {
      id: object::new(ctx),
      escrow: escrow_id
    };    

    (agent, recipient, sender)
  }  

  #[lint_allow(self_transfer)]
  public fun new_and_transfer<T: store>(_sender: address, _recipient: address, ctx: &mut TxContext) {
    let (agent, recipient, sender) = new<T>(ctx);
    transfer::transfer(agent, tx_context::sender(ctx));
    transfer::transfer(recipient, _recipient);
    transfer::transfer(sender, _sender);
  } 

  public fun add<T: store>(self: &mut Escrow<T>, cap: &Access<Sender>, item: T) {
    assert!(object::id(self) == cap.escrow, EUnauthorizedSender);

    option::fill(&mut self.item, item);
  }

  public fun remove<T: store>(self: Escrow<T>, cap: Access<Sender>): T {
    assert!(object::id(&self) == cap.escrow, EUnauthorizedSender);
    assert!(!self.validated, ECannotRemoveItemAfterValidation);

    destroy_access(cap);

    destroy_escrow_and_get_item(self)
  }

  public fun validate<T: store>(self: &mut Escrow<T>, cap: &Access<Agent>) {
    assert!(object::id(self) == cap.escrow, EUnauthorizedAgent);
    assert!(option::is_some(&self.item), ECannotValidateAnEmptyEscrow);

    self.validated = true;
  }    

  public fun receive<T: store>(self: Escrow<T>, cap: Access<Recipient>): T {
    assert!(object::id(&self) == cap.escrow, EUnauthorizedRecipient);
    assert!(self.validated, ECannotReceiveInvalidEscrow);

    destroy_access(cap);

    destroy_escrow_and_get_item(self)
  }

  public fun destroy_empty_escrow<T: store>(self: Escrow<T>, cap: Access<Agent>) {
    assert!(option::is_none(&self.item), EEscrowMustBeEmpty);
    assert!(object::id(&self) == cap.escrow, EOnlyAgentCanDestroyAnEscrow);

    destroy_access(cap);

    let Escrow { id, item, validated: _ } = self;

    option::destroy_none(item);
    object::delete(id);
  }

  public fun destroy_access<T>(cap: Access<T>) {
    let Access { id, escrow: _ } = cap;
    object::delete(id);  
  }

  // === Public-View Functions ===

  public fun validated<T:store>(self: &Escrow<T>): bool {
    self.validated
  }  

  public fun item<T:store>(self: &Escrow<T>): &Option<T> {
    &self.item
  }   

  public fun escrow<T>(self: &Access<T>): ID {
    self.escrow
  }


  // === Private Functions ===
  fun destroy_escrow_and_get_item<T: store>(self: Escrow<T>): T {
    let Escrow { id, item, validated: _ } = self;

    object::delete(id);
    
    let r = option::extract(&mut item);

    option::destroy_none(item);

    r
  }
}