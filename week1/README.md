# Sui Course Cluster 1

## Contracts

- dex: Basic implementation of a DEX swap function
- curve: Curve logic to determine the swap amounts
- admin: Creates a singleton Admin object
- faucet: Faucet to mint ETH and USDC
- utils: Utility functions to handle type comparisons

## Object Ids

- PackageId: TBA
- Faucet object id: TBA
- Pool object id: TBA

## Tasks

1.  Mint USDC and ETH
2.  Swap USDC -> ETH
3.  Swap ETH -> USDC
4.  Implement extra functionalities **(Examples Below)**
    - Add/Remove liquidity
    - Flash Loans
    - Swap Fee
    - Oracle
    - Different Curve
    - Limited Orders
    - Farms

## Mint USDC and ETH

**Switch to the testnet on the CLI**

```console
sui client switch --env testnet
```

**Check your active address**

```console
sui client active-address
```

**Request Testnet Sui**

```console
curl --location --request POST 'https://faucet.testnet.sui.io/gas' \
--header 'Content-Type: application/json' \
--data-raw '{
    "FixedAmountRequest": {
        "recipient": "<YOUR SUI ADDRESS>"
    }
}'
```

**Mint USDC**

```console
sui client call --package <PACKAGE_ID> --module faucet --function mint_usdc --args <FAUCET_OBJECT_ID> <CLOCK_OBJECT_ID>
```

## Swap USDC -> ETH

The swap function returns an object, which requires handling. Please write use the TS SDK to handle it.

Below we will provide the signature of the Move call.

```ts
(async () => {
  try {
    //create Transaction Block.
    const txb = new TransactionBlock();

    // Call the DEX
    const coin_out = txb.moveCall({
      target: `${PACKAGE_ID}::dex::swap`,
      typeArguments: [COIN_USDC_TYPE, COIN_ETH_TYPE],
      arguments: [txb.object(POOL_OBJECT_ID), txb.object(COIN_OBJECT_ID)],
    });

    // TODO: Handle the Returned Object

    // Submit
    let txid = await client.signAndExecuteTransactionBlock({
      signer: keypair,
      transactionBlock: txb,
    });
  } catch (e) {
    console.error(`Oops, something went wrong: ${e}`);
  }
})();
```
