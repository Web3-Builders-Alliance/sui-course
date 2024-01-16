import { getFullnodeUrl, SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { TransactionBlock } from '@mysten/sui.js/transactions';
import wallet from "../dev-wallet.json"

const keypair = Ed25519Keypair.fromSecretKey(new Uint8Array(wallet));
const to = "0x5a8d7647cc82adc39d1f6d74426b7263853054ba874108f404622a1b9b1faa2c";
const client = new SuiClient({ url: getFullnodeUrl("devnet") });

(async () => {
    try {
        const txb = new TransactionBlock();
        let [coin] = txb.splitCoins(txb.gas, [1000]);
        txb.transferObjects([coin], to);
        let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
        console.log(`Success! Check our your TX here:
        https://suiexplorer.com/txblock/${txid.digest}?network=devnet`);
    } catch(e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();