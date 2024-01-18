module week1::curve {

  use suitears::math256::div_down;

  const ENoZeroCoin: u64 = 0;
  const EInsufficientLiquidity: u64 = 1;

  public fun invariant_(x: u64, y: u64): u256 {
     (x as u256) * (y as u256)
  }

  public fun get_amount_out(coin_in_amount: u64, balance_in: u64, balance_out: u64): u64 {
    assert!(coin_in_amount != 0, ENoZeroCoin);
    assert!(balance_in != 0 && balance_out != 0, EInsufficientLiquidity);
    let (coin_in_amount, balance_in, balance_out) = (
          (coin_in_amount as u256),
          (balance_in as u256),
          (balance_out as u256)
        );

        let numerator = balance_out * coin_in_amount;
        let denominator = balance_in + coin_in_amount; 

        (div_down(numerator, denominator) as u64) 
  }
}