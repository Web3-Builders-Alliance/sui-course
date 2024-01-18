import { getFullnodeUrl, SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { TransactionBlock, TransactionObjectInput } from '@mysten/sui.js/transactions';
import wallet from "./dev-publisher.json"
import { bcs } from '@mysten/sui.js/bcs';



const keypair = Ed25519Keypair.fromSecretKey(new Uint8Array(wallet));
const client = new SuiClient({ url: getFullnodeUrl("devnet") });

const enrollment_object_id = "0x8a01cf24865096d16381f085707026a924c63f18ea39f14dec772b363818a1f7";
const instructor_cap = "0x70df090e3c838b70905ccbe0086ed7ad97f1695f36e870477b60579f7b7b3daa";
const cohort = "0xe8839db08ebad8badaaf30312f57741796162599bd30188a15c0f1dec2d37a87";

(async () => {
    try {
        const txb = new TransactionBlock();
        let hort_obj = await client.getObject({id:cohort, options:{showContent:true}});
       
        let createed = txb.moveCall({
            target: `${enrollment_object_id}::enrollment::create_cohort`,
            arguments: [txb.object(instructor_cap)],
        });

        let enabled = txb.moveCall({
            target: `${enrollment_object_id}::enrollment::toggle_signups`,
            arguments: [txb.object(instructor_cap), txb.object(cohort)],
        });

        // const github = new Uint8Array(Buffer.from("testgithub"));
        // let serialized_github = txb.pure(bcs.vector(bcs.u8()).serialize(github));


        // let enroll = txb.moveCall({
        //     target: `${enrollment_object_id}::enrollment::enroll`,
        //     arguments: [serialized_github, txb.object(cohort)],
        // });


        let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb , options:{showEffects:true}});
        
        console.log(`Success! Check our your TX here:
        https://suiexplorer.com/txblock/${txid.digest}?network=devnet`);
    } catch(e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();