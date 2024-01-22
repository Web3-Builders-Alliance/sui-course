module functions::two {

  friend functions::interface;

  // Only friend modules can call this function. 
  public(friend) fun two_impl(): u64 {
    2
  }
}