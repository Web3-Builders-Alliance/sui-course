module sui_bank::oracle {
  // === Imports ===

  use sui::math as sui_math;

  use switchboard::aggregator::{Self, Aggregator};
  use switchboard::math;

  // === Errors ===

  const EPriceIsNegative: u64 = 0;

  // === Structs ===

  struct Price {
    latest_result: u128,
    scaling_factor: u128,
    latest_timestamp: u64,
  }

  // === Public-Mutative Functions ===

  public fun new(feed: &Aggregator): Price {
    let (latest_result, latest_timestamp) = aggregator::latest_value(feed);

    let (value, scaling_factor, neg) = math::unpack(latest_result);

    assert!(!neg, EPriceIsNegative);

    Price {
      latest_result: value,
      scaling_factor: (sui_math::pow(10, scaling_factor) as u128),
      latest_timestamp
    }
  }

  public fun destroy(self: Price): (u128, u128, u64) {
    let Price { latest_result, scaling_factor, latest_timestamp } = self;
    (latest_result, scaling_factor, latest_timestamp)
  }

  // === Test Functions ===

  #[test_only]
  
  public fun new_for_testing(latest_result: u128, scaling_factor: u128, latest_timestamp: u64): Price {
    Price {
      latest_result,
      scaling_factor,
      latest_timestamp
    }
  }
}