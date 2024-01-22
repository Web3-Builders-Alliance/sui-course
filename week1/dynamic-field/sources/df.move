module df::df {
  use std::type_name::{Self, TypeName};
  
  use sui::dynamic_field;
  use sui::object::UID;

  /*
  * It adds dynamic fields to an object.  
  * Dyanmic field is used to add structs with the store ability.
  * It will wrap the struct into an object.  
  *
  * This is what makes dynamic NFTs possible and collections such as Table. 
  */

  // The key of the dyanmic field has to be a struct with these 3 abilities
  struct Key has copy, drop, store { name: TypeName }

  // We can add infinite fields
  struct Parent has key {
    id: UID
  }

  public fun add<T: store>(self: &mut Parent, data: T) {
    dynamic_field::add(&mut self.id, Key { name: type_name::get<T>() }, data);
  }

  public fun remove<T: store>(self: &mut Parent): T {
    dynamic_field::remove<Key, T>(&mut self.id, Key { name: type_name::get<T>() })
  }

  public fun borrow<T: store>(self: &Parent): &T {
    dynamic_field::borrow<Key, T>(&self.id, Key { name: type_name::get<T>() })
  }

  public fun borrow_mut<T: store>(self: &mut Parent): &mut T {
    dynamic_field::borrow_mut<Key, T>(&mut self.id, Key { name: type_name::get<T>() })
  }  
}