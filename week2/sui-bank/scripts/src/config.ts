import { getFullnodeUrl, SuiClient } from '@mysten/sui.js/client';
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import dotenv from "dotenv";

dotenv.config();

export const keypair = Ed25519Keypair.fromSecretKey(Uint8Array.from(Buffer.from(process.env.KEY!, "base64")).slice(1));

export const client = new SuiClient({ url: getFullnodeUrl('testnet') });

// ---------------------------------

export const PACKAGE = "0x3c294b29f2d94bf6e664962cde04ea14e371e737cef86e559f1963eaab8a9c89";
export const BANK = "0xaa6131a7e9c0b5392625969146f68369b4825cb2174b2141dfefdbd66ac904fa";
export const ACCOUNT = ""