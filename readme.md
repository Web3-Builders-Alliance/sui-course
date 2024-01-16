# Prerequisites: Enrollment dApp

In this lesson, we are going to: 
1. Learn how to use `@mysten/sui.js` to create a new keypair
2. Use our Public Key to airdrop ourselves some Sui devnet tokens
3. Make Sui transfers on devnet
4. Empty your devnet wallet into your WBA wallet
5. Use our WBA Private Key to enroll in the WBA enrollment dApp

Prerequisites:
1. Have NodeJS installed
2. Have yarn installed
3. Have a fresh folder created to follow this tutorial and all future tutorials

Let's get into it!

## 1. Create a new Keypair

To get started, we're going to create a keygen script and an airdrop script for our account.

#### 1.1 Setting up
Start by opening up your Terminal. We're going to use `yarn` to create a new Typescript project.

```sh
mkdir prereq && cd prereq
yarn init -y
```

Now that we have our new project initialised, we're going to go ahead and add `typescript`, `bs58` and `@mysten/sui.js`, along with generating a `tsconfig.js` configuration file.

```sh
yarn add @types/node typescript @mysten/sui.js bs58
yarn add -D ts-node
touch keygen.ts
touch airdrop.ts
touch transfer.ts
touch enroll.ts
yarn tsc --init --rootDir ./ --outDir ./dist --esModuleInterop --lib ES2019 --module commonjs --resolveJsonModule true --noImplicitAny true
```

Finally, we're going to add some scripts in our `package.json` file to let us run the four scripts we're going to build today:

```js
{
  "name": "prereq",
  "version": "1.0.0",
  "main": "index.js",
  "license": "MIT",
  "scripts": {
    "keygen": "ts-node ./keygen.ts",
    "airdrop": "ts-node ./airdrop.ts",
    "transfer": "ts-node ./transfer.ts",
    "enroll": "ts-node ./enroll.ts"
  },
  "dependencies": {
    "@mysten/sui.js": "^0.49.0",
    "@types/node": "^18.15.11",
    "typescript": "^5.0.4"
  },
  "devDependencies": {
    "ts-node": "^10.9.1"
  }
}
```

Alright, we're ready to start getting into the code!

#### 1.2 Generating a Keypair
Open up `./keygen.ts`. We're going to generate ourselves a new keypair. Sui supports multiple types of Keypairs but we will be using Ed25519.

We'll start by importing `Keypair` from `@mysten/sui.js`

```ts
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { fromB64 } from "@mysten/sui.js/utils";
```

Now we're going to create a new Keypair, like so:

```ts
let kp = Ed25519Keypair.generate();
console.log(`You've generated a new Sui wallet: ${kp.toSuiAddress()}

To save your wallet, copy and paste the following into a JSON file:

[${fromB64(kp.export().privateKey)}]\n

You can use the below HEX to import the key into a web wallet:

${toHEX(fromB64(kp.export().privateKey))}\n`);
```

Now we can run the following script in our terminal to generate a new keypair!

```sh
yarn keygen
```

This will generate a new Keypair, outputting its Address and Private Key like so:
```
You've generated a new Solana wallet: 0xf4a202b4883cb5b86a7b3a1573695019b646f86115ffdca623c98b99140c10fc

To save your wallet, copy and paste your private key into a JSON file:

[91,148,165,44,176,23,3,34,241,109,55,196,245,26,167,220,155,131,49,23,168,115,195,112,146,72,50,95,213,137,211,6]
```

If we want to save this wallet locally. To do this, we're going run the following command:

```sh
touch dev-wallet.json
```
This creates the file `dev-wallet.json` in our `./prereq` root directory. Now we just need to paste the private key from above into this file, like so:

```json
[91,148,165,44,176,23,3,34,241,109,55,196,245,26,167,220,155,131,49,23,168,115,195,112,146,72,50,95,213,137,211,6]
```

Congrats, you've created a new Keypair and saved your wallet. Let's go claim some tokens!

### 1.3 Import/Export to Suiet(or another wallet.)
Sui wallet files and wallets like Suiet use different encoding. While the Sui SDK can use multiple encodings like a byte array, base64, and Hex, Suiet uses a Hex encoded string representation of private keys. 

## 2. Claim Token Airdrop
Now that we have our wallet created, we're going to import it int './airdrop.ts'.

This time, we're going to import `Ed25519Keypair`, but we're also going to import `requestSuiFromFaucetV0` and `getFaucetHost` to let us request a airdrop for the Sui devnet.

```ts
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { getFaucetHost, requestSuiFromFaucetV0 } from "@mysten/sui.js/faucet";
```

We're also going to import our wallet and recreate the `Keypair` object using its private key:

```ts
import wallet from "./dev-wallet.json"

// We're going to import our keypair from the wallet file
const keypair = Keypair.fromSecretKey(new Uint8Array(wallet));
```

Now lets send off that airdrop reqest for Devnet Sui:
```ts
((async () => {
    try {
        let res = await requestSuiFromFaucetV0({
            host: getFaucetHost("devnet"),
            recipient: keypair.toSuiAddress(),
          });
          console.log(`Success! Check our your TX here:
          https://suiscan.xyz/devnet/object/${res.transferredGasObjects[0].id}`);
    } catch(e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();
```

Here is an example of the output of a successful airdrop:

```
Success! Check out your TX here:
https://suiscan.xyz/devnet/object/0x69bb5db57b07bee4dc2a141fa02aeafc892fcc5a14627a2f7c2dc1859ce8b9a2
```

## 3. Transfer tokens to your WBA Address
Now we have some devnet SUI to play with, it's time to transfer our first object, SUI. When you first signed up for the course, you gave WBA a SUI address for certification. We're going to be sending some devnet SUI to this address so we can use it going forward.

We're gong to open up `transfer.ts` and import the following items from `@mysten/sui.js`:
```ts
import { getFullnodeUrl, SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { TransactionBlock } from '@mysten/sui.js/transactions';
```

We will also import our dev wallet as we did last time:
```ts
import wallet from "./dev-wallet.json"

// Import our dev wallet keypair from the wallet file
const keypair = Ed25519Keypair.fromSecretKey(new Uint8Array(wallet));

// Define our WBA SUI Address
const to = "0xcd639240b79c9ca1677418b4c6a49b9503a65d84a3763772f55d59359e981ec2";
```

And create a devnet client:
 
```ts
//Create a Sui devnet client
const client = new SuiClient({ url: getFullnodeUrl("devnet")});
```

Now we're going to create a programable transaction block using `'@mysten/sui.js/transactions'` to transfer 1000 Mist from our dev wallet to our WBA wallet address on the Sui devenet. To complete this task we will need to split our SUI coin object.
```ts
(async () => {
    try {
        //create Transaction Block.
        const txb = new TransactionBlock();
        //Split coins
        let [coin] = txb.splitCoins(txb.gas, [1000]);
        //Add a transferObject transaction
        txb.transferObjects([coin, txb.gas], to);
        let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
        console.log(`Success! Check our your TX here:
        https://suiexplorer.com/txblock/${txid.digest}?network=devnet`);
    } catch(e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();
```

## 4. Empty devnet wallet into WBA wallet

Okay, now that we're done with our devnet wallet, let's also go ahead and send all of our remaining mist to our WBA dev wallet. It is typically good practice to know how to empty a wallet completely as it allows us to reclaim resources that aren't being used.

To send all of the remaining mist out of our dev wallet to our WBA wallet, we should only have one coin object belonging to our key, so to get this to work all we need to do is remove a few things.
1. Remove split coins.
2. Include only the gas coin as an input.

```ts
(async () => {
    try {
        //create Transaction Block.
        const txb = new TransactionBlock();
        //Add a transferObject transaction
        txb.transferObjects([txb.gas], to);
        let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
        console.log(`Success! Check our your TX here:
        https://suiexplorer.com/txblock/${txid.digest}?network=devnet`);
    } catch(e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();
```

You can see from the outputted transaction block on the SUI explorer that the entire object was transfered.
```
Check out your TX here:
https://explorer.solana.com/tx/4dy53oKUeh7QXr15wpKex6yXfz4xD2hMtJGdqgzvNnYyDNBZXtcgKZ7NBvCj7PCYU1ELfPZz3HEk6TzT4VQmNoS5?cluster=devnet
```

## 5. Submit your completion of the WBA pre-requisites program
When you first signed up for the course, you gave WBA a Solana address for certification and your Github account. Your challenge now is to use the devnet tokens you just airdropped and transferred to yourself to confirm your enrollment in the course on the Sui devnet.

In order to do this, we're going to have to quickly familiarise ourselves with two key concepts of Sui:

1. **PTB (Programable Transaction Blocks)** - A PTB allows us to create complex and atomic transactions that touch multiple objects, types, functions, etc... There will be many use cases where you can use a PTB instead of putting a module on chain!

1. **Move Calls** - Move calls allow you to interact with a modules entry functions, you can use the block explorer to quickly play with modules on chain, but in this example we will use the Sui TS Sdk.

Let's dive into it!

#### 5.1 Looking at the Explorer to 
For the purposes of this class, we have published a WBA pre-requisite course program to the Sui Devnet.

You can find our enrollment module on Devnet by this address: [0x8a01cf24865096d16381f085707026a924c63f18ea39f14dec772b363818a1f7](https://suiexplorer.com/object/0x8a01cf24865096d16381f085707026a924c63f18ea39f14dec772b363818a1f7?module=enrollment&network=devnet)

If we explore the devnet explorer, there is a section called "[Execute] which gives us a easy way to interact with a module, instead of using that lets do it in typescript instead.

We want you to call the enroll function and pass in a byte representation of the utf8 string of your github account name

Now let's open up `enroll.ts` and define the following imports:

```ts
import { getFullnodeUrl, SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { bcs} from "@mysten/sui.js/bcs";
import { TransactionBlock } from '@mysten/sui.js/transactions';
import wallet from "../wba-wallet.json"
```

Note that we've imported a new wallet filed called `wba-wallet.json`. Unlike the dev-wallet.json, this should contain the private key for an account you might care about. To stop you from accidentally comitting your private key(s) to a git repo, consider adding a `.gitignore` file. Here's an example that will ignore all files that end in `wallet.json`:

```.gitignore
*wallet.json
```

As with last time, we're going to create a keypair and a client:
```ts



// We're going to import our keypair from the wallet file
const keypair = Ed25519Keypair.fromSecretKey(new Uint8Array(wallet));

// Create a devnet client
const client = new SuiClient({ url: getFullnodeUrl("devnet") });
```



To register ourselves as having completed pre-requisites, we need to create a PTB submit our github account name as a utf8 buffer:

```ts
const txb = new TransactionBlock(;
```

Next we will convert our github username into a byte array and then use BCS to serialize it. BCS is a serialization format that is compatable with Sui Move and the Sui TS SDK. 

```ts
// Github account
const github = new Uint8Array(Buffer.from("-your github account-"));
let serialized_github = txb.pure(bcs.vector(bcs.u8()).serialize(github));
```

Now, we can create a Move Call and talk to the onchain module.

```ts
let enroll = txb.moveCall({
    target: `${enrollment_object_id}::enrollment::enroll`,
    arguments: [serialized_github, txb.object(cohort)],
});
```

The final setp is to have our client sign and execute our PTB.

```ts
let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
console.log(`Success! Check our your TX here:
https://suiexplorer.com/txblock/${txid.digest}?network=devnet`);
```

#### 5.3 Putting it all together
Now that we have everything we need, it's finally time to put it all together and make a transaction interacting with the devnet program to submit our `github` account and our `publicKey` to signify our completion of the WBA pre-requisite materials!

Congratulations, you have enrolled and completed the WBA Sui Q1 Pre-requisite coursework!