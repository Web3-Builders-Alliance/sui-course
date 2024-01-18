module amm::utils {
  use std::type_name;

  use suitears::comparator;

  const EChooseDifferentCoins: u64 = 0;

  public fun are_coins_ordered<CoinA, CoinB>(): bool {
    let coin_a_type_name = type_name::get<CoinA>();
    let coin_b_type_name = type_name::get<CoinB>();
    
    assert!(coin_a_type_name != coin_b_type_name, EChooseDifferentCoins);
    
    comparator::lt(&comparator::compare(&coin_a_type_name, &coin_b_type_name))
  }

  public fun is_coin_x<CoinA, CoinB>(): bool {
    comparator::lt(&comparator::compare(&type_name::get<CoinA>(), &type_name::get<CoinB>()))
  }  
}