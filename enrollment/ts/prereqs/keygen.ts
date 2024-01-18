import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { fromB64, toHEX } from "@mysten/sui.js/utils";

//Generate a new keypair
let kp = Ed25519Keypair.generate()
console.log(`You've generated a new Sui wallet: ${kp.toSuiAddress()}

To save your wallet, copy and paste the following into a JSON file:

[${fromB64(kp.export().privateKey)}]\n

You can use the below HEX to import the key into a web wallet:

${toHEX(fromB64(kp.export().privateKey))}\n`);