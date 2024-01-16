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

Finally, we're going to create some scripts in our `package.json` file to let us run the three scripts we're going to build today:

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
//Generate a new keypair
let kp = Ed25519Keypair.generate()
console.log(`You've generated a new Sui wallet: ${kp.toSuiAddress()}

To save your wallet, copy and paste the following into a JSON file:

[${kp.export().privateKey}]`)
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

### NOT DONE
### 1.3 Import/Export to Phantom
Solana wallet files and wallets like Phantom use different encoding. While Solana wallet files use a byte array, Phantom uses a base58 encoded string representation of private keys. If you would like to go between these formats, try import the `bs58` package. We'll also use the `prompt-sync` package to take in the private key: 

```sh
yarn add bs58 prompt-sync
```

```ts
import bs58 from 'bs58'
import * as prompt from 'prompt-sync
```

Now add in the following two convenience functions to your tests and you should have a simple CLI tool to convert between wallet formats:

```ts
#[test]
fn base58_to_wallet() {
    println!("Enter your name:");
    let stdin = io::stdin();
    let base58 = stdin.lock().lines().next().unwrap().unwrap(); // gdtKSTXYULQNx87fdD3YgXkzVeyFeqwtxHm6WdEb5a9YJRnHse7GQr7t5pbepsyvUCk7VvksUGhPt4SZ8JHVSkt
    let wallet = bs58::decode(base58).into_vec().unwrap();
    println!("{:?}", wallet);
}

#[test]
fn wallet_to_base58() {
    let wallet: Vec<u8> = vec![34,46,55,124,141,190,24,204,134,91,70,184,161,181,44,122,15,172,63,62,153,150,99,255,202,89,105,77,41,89,253,130,27,195,134,14,66,75,242,7,132,234,160,203,109,195,116,251,144,44,28,56,231,114,50,131,185,168,138,61,35,98,78,53];
    let base58 = bs58::encode(wallet).into_string();
    println!("{:?}", base58);
}
```


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
When you first signed up for the course, you gave WBA a Solana address for certification and your Github account. Your challenge now is to use the devnet tokens you just airdropped and transferred to yourself to confirm your enrollment in the course on the Solana devnet.

In order to do this, we're going to have to quickly familiarise ourselves with two key concepts of Solana:

1. **PDA (Program Derived Address)** - A PDA is used to enable our program to "sign" transactions with a Public Key derived from some kind of deterministic seed. This is then combined with an additional "bump" which is a single additional byte that is generated to "bump" this Public Key off the elliptic curve. This means that there is no matching Private Key for this Public Key, as if there were a matching private key and someone happened to possess it, they would be able to sign on behalf of the program, creating security concerns.

2. **IDL (Interface Definition Language)** - Similar to the concept of ABI in other ecosystems, an IDL specifies a program's public interface. Though not mandatory, most programs on Solana do have an IDL, and it is the primary way we typically interact with programs on Solana. It defines a Solana program's account structures, instructions, and error codes. IDLs are .json files, so they can be used to generate client-side code, such as Typescript type definitions, for ease of use.

Let's dive into it!

#### 5.1 Consuming an IDL in Typescript
For the purposes of this class, we have published a WBA pre-requisite course program to the Solana Devnet with a public IDL that you can use to provide onchain proof that you've made it to the end of our pre-requisite coursework. 

You can find our program on Devnet by this address: [HC2oqz2p6DEWfrahenqdq2moUcga9c9biqRBcdK3XKU1](https://explorer.solana.com/address/HC2oqz2p6DEWfrahenqdq2moUcga9c9biqRBcdK3XKU1?cluster=devnet)

If we explore the devnet explorer, there is a tab called "[Anchor Program IDL](https://explorer.solana.com/address/HC2oqz2p6DEWfrahenqdq2moUcga9c9biqRBcdK3XKU1/anchor-program?cluster=devnet)" which reveals the IDL of our program. If you click the clipboard icon at the top level of this JSON object, you can copy the IDL directly from the browser. The result should look something like this:

```json
{
  "version": "0.1.0",
  "name": "wba_prereq",
  "instructions": [
    {
      "name": "complete",
      ...
    }
  ]
}
```

As you can see, this defines the schema of our program with a single instruction called `complete` that takes in 1 argument:
1. `github` - a byte representation of the utf8 string of your github account name

As well as 3 accounts:
1. `signer` - your public key you use to sign up for the WBA course
2. `prereq` - an account we create in our program with a custom PDA seed (more on this later)
3. `systemAccount` - the Solana system program which is used to execute account instructions

In order for us to consume this in typescript, we're going to go and create a `type` and an `object` for it. Let's start by creating a folder in our root directory called `programs` so we can easily add additional program IDLs in the future, along with a new typescript file called `wba_prereq.ts`.

```sh
mkdir programs
touch ./programs/wba_prereq.ts
```

Now that we've created the `wba_prereq.ts` file, we're going to open it up and create our `type` and `object`.

```ts
export type WbaPrereq =  = { "version": "0.1.0", "name": "wba_prereq", ...etc }
export const IDL: WbaPrereq = { "version": "0.1.0", "name": "wba_prereq", ...etc }
```

Our `type` and `object` are now ready to import this into Typescript, but to actually consume it, first, we're going to need to install Anchor, a Solana development framework, as well as define a few other imports.

Let's first install `@project-serum/anchor`:
```sh
yarn add @project-serum/anchor
```

Now let's open up `enroll.ts` and define the following imports:

```ts
import { Connection, Keypair, SystemProgram, PublicKey } from "@solana/web3.js"
import { Program, Wallet, AnchorProvider, Address } from "@project-serum/anchor"
import { WbaPrereq, IDL } from "./programs/wba_prereq";
import wallet from "./wba-wallet.json"
```

Note that we've imported a new wallet filed called `wba-wallet.json`. Unlike the dev-wallet.json, this should contain the private key for an account you might care about. To stop you from accidentally comitting your private key(s) to a git repo, consider adding a `.gitignore` file. Here's an example that will ignore all files that end in `wallet.json`:

```.gitignore
*wallet.json
```

As with last time, we're going to create a keypair and a connection:
```ts
// We're going to import our keypair from the wallet file
const keypair = Keypair.fromSecretKey(new Uint8Array(wallet));

// Create a devnet connection
const connection = new Connection("https://api.devnet.solana.com");
```

To register ourselves as having completed pre-requisites, we need to submit our github account name as a utf8 buffer:
```ts
// Github account
const github = Buffer.from("<your github account>", "utf8");
```

Now we're going to use our connection and wallet to create an Anchor provider:
```ts
// Create our anchor provider
const provider = new AnchorProvider(connection, new Wallet(keypair), { commitment: "confirmed"});
```

Finally, we can use the Anchor `provider`, our IDL `object` and our IDL `type` to create our anchor `program`, allowing us to interact with the WBA prerequisite program.
```ts
// Create our program
const program = new Program<WbaPrereq>(IDL, "HC2oqz2p6DEWfrahenqdq2moUcga9c9biqRBcdK3XKU1" as Address, provider);
```

#### 5.2 Creating a PDA
Now we need to create a PDA for our `prereq` account. The seeds for this particular PDA are:

1. A Utf8 `Buffer` of the `string`: "prereq"
2. The `Buffer` of the public key of the transaction signer

There are then combined into a single Buffer, along with the `program` ID, to create a deterministic address for this account. The `findProgramAddressSync` function is then going to combine this with a `bump` to find an address that is not on the elliptic curve and return the derived address, as well as the bump which we will not be using in this example:

```ts
// Create the PDA for our enrollment account
const enrollment_seeds = [Buffer.from("prereq"), keypair.publicKey.toBuffer()];
const [enrollment_key, _bump] = PublicKey.findProgramAddressSync(enrollment_seeds, program.programId);
```

Remember to familiarize yourself with this concept as you'll be using it often!

#### 5.3 Putting it all together
Now that we have everything we need, it's finally time to put it all together and make a transaction interacting with the devnet program to submit our `github` account and our `publicKey` to signify our completion of the WBA pre-requisite materials!

```ts
// Execute our enrollment transaction
(async () => {
    try {
        const txhash = await program.methods
        .complete(github)
        .accounts({
            signer: keypair.publicKey,
            prereq: enrollment_key,
            systemProgram: SystemProgram.programId,
        })
        .signers([
            keypair
        ]).rpc();
        console.log(`Success! Check out your TX here: 
        https://explorer.solana.com/tx/${txhash}?cluster=devnet`);
    } catch(e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();
```

Congratulations, you have completed the WBA Solana Q2 Pre-requisite coursework!