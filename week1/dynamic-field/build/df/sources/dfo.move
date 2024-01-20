module df::dfo {
  use std::type_name::{Self, TypeName};
  
  use sui::dynamic_object_field;
  use sui::object::UID;

  /*
  * It adds dynamic fields to an object.  
  * Dyanmic Object field is used to add structs with the store and key abilities.
  * It will NOT wrap the object on a new object. You can simply grab the field data by its UID on the frontend.   
  *
  * This is what makes dynamic NFTs possible and collections such as Table. 
  */

  // The key of the dyanmic field has to be a struct with these 3 abilities
  struct Key has copy, drop, store { name: TypeName }

  // We can add infinite fields
  struct Parent has key {
    id: UID
  }

  public fun add<T: store + key>(self: &mut Parent, data: T) {
    dynamic_object_field::add(&mut self.id, Key { name: type_name::get<T>() }, data);
  }

  public fun remove<T: store + key>(self: &mut Parent): T {
    dynamic_object_field::remove<Key, T>(&mut self.id, Key { name: type_name::get<T>() })
  }

  public fun borrow<T: store + key>(self: &Parent): &T {
    dynamic_object_field::borrow<Key, T>(&self.id, Key { name: type_name::get<T>() })
  }

  public fun borrow_mut<T: store + key>(self: &mut Parent): &mut T {
    dynamic_object_field::borrow_mut<Key, T>(&mut self.id, Key { name: type_name::get<T>() })
  }  
}