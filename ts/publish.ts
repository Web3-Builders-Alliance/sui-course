import { getFullnodeUrl, SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import {normalizeSuiObjectId, fromB64} from "@mysten/sui.js/utils";
import { TransactionBlock } from '@mysten/sui.js/transactions';
import wallet from "./dev-wallet.json"
import { execSync } from "child_process";
import fs from "fs";

const network = "devnet";

const keypair = Ed25519Keypair.fromSecretKey(new Uint8Array(wallet));
const client = new SuiClient({ url: getFullnodeUrl("devnet") });

interface Program {
    modules: string[];
    dependencies: string[];
}

(async () => {
    try {
        let program = buildPackage("/Users/ivmidable/Development/sui/sui-course")
        
        console.log(program);
        const txb = new TransactionBlock();

        const [upgradeCap] = txb.publish({
            modules: program.modules.map((m) => Array.from(fromB64(m))),
            dependencies: program.dependencies.map((d) => normalizeSuiObjectId(d)),
          });
      
          // Transfer upgrade capability to deployer
          txb.transferObjects([upgradeCap], txb.pure(await keypair.toSuiAddress()));


        if (network === "devnet") {
            // Avoid Error checking transaction input objects: GasBudgetTooHigh { gas_budget: 50000000000, max_budget: 10000000000 }
            txb.setGasBudget(10000000000);
          }

        let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
        
        console.log(`Success! Check our your TX here:
        https://suiexplorer.com/txblock/${txid.digest}?network=devnet\n`);

        console.log(txid);
    } catch(e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();

function buildPackage(packagePath: string): Program {
    if (!fs.existsSync(packagePath)) {
      throw new Error(`Package not found at ${packagePath}`);
    }
  
    return JSON.parse(
      execSync(
        `sui move build --skip-fetch-latest-git-deps --dump-bytecode-as-base64 --path ${packagePath} 2> /dev/null`,
        {
          encoding: "utf-8",
        }
      )
    );
  };