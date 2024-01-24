import { getFullnodeUrl, SuiClient, SuiTransactionBlockResponseOptions } from "@mysten/sui.js/client";
import {
  TransactionBlock
} from "@mysten/sui.js/transactions";
import { bcs } from "@mysten/sui.js/bcs";
import { Ed25519Keypair } from "@mysten/sui.js/dist/cjs/keypairs/ed25519";
import { Secp256k1Keypair } from "@mysten/sui.js/dist/cjs/keypairs/secp256k1";
import { Secp256r1Keypair } from "@mysten/sui.js/dist/cjs/keypairs/secp256r1";

export default class Enrollment {
  private client: SuiClient;
  private txb: TransactionBlock;
  private enrollment_obj: string;
  private instructor_cap: string;
  private cohort_obj: string | undefined;
  private endpoint: string;

  constructor(
    enrollment_object: string,
    instructor_cap: string,
    endpoint:string = "testnet"
  ) {
    this.endpoint = endpoint;
    this.enrollment_obj = enrollment_object;
    this.instructor_cap = instructor_cap;
    this.client = new SuiClient({ url: getFullnodeUrl(this.endpoint as any) });
    this.txb = new TransactionBlock();
  }

  public async rpc(signer: Ed25519Keypair | Secp256k1Keypair | Secp256r1Keypair, options: SuiTransactionBlockResponseOptions | undefined) {
    let txid = await this.client.signAndExecuteTransactionBlock({
        signer: signer,
        transactionBlock: this.txb,
        options: options,
      });
  
      console.log(`Success! Check our your TX here:
      https://suiexplorer.com/txblock/${txid.digest}?network=${this.endpoint}`);
  }

  public get_txb() {
    return this.txb;
  }

  public get_client() {
    return this.client;
  }

  public add_enrollment_obj(enrollment_object: string) {
    this.enrollment_obj = enrollment_object;
    return this;
  }

  public add_instructor_cap(instructor_cap: string) {
    this.instructor_cap = instructor_cap;
    return this;
  }

  public add_cohort_obj(cohort_obj: string) {
    this.cohort_obj = cohort_obj;
    return this;
  }

  public create_cohort(name: string) {
    let created = this.txb.moveCall({
      target: `${this.enrollment_obj}::enrollment::create_cohort`,
      arguments: [this.txb.object(this.instructor_cap)],
    });
    return this;
  }

  public toggle_signups() {
    if (this.cohort_obj == undefined) {
      throw "No cohort object provided.";
    }
    let enabled = this.txb.moveCall({
      target: `${this.enrollment_obj}::enrollment::toggle_signups`,
      arguments: [
        this.txb.object(this.instructor_cap),
        this.txb.object(this.cohort_obj),
      ],
    });
    return this;
  }

  public enroll(github: string) {
    if (this.cohort_obj == undefined) {
      throw "No cohort object provided.";
    }

    const github_bytes = new Uint8Array(Buffer.from(github));
    let serialized_github = this.txb.pure(
      bcs.vector(bcs.u8()).serialize(github_bytes)
    );

    let enroll = this.txb.moveCall({
      target: `${this.enrollment_obj}::enrollment::enroll`,
      arguments: [this.txb.object(this.cohort_obj), serialized_github],
    });

    return this;
  }

  public update(github: string) {
    if (this.cohort_obj == undefined) {
      throw "No cohort object provided.";
    }

    const github_bytes = new Uint8Array(Buffer.from(github));
    let serialized_github = this.txb.pure(
      bcs.vector(bcs.u8()).serialize(github_bytes)
    );

    let update = this.txb.moveCall({
      target: `${this.enrollment_obj}::enrollment::update`,
      arguments: [this.txb.object(this.cohort_obj), serialized_github],
    });

    return this;
  }
}
