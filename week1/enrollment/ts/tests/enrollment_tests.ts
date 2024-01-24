import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import Enrollment from "../enrollment";

import wallet from "../dev-wallet.json";


describe("enrollment-package", () => {
  const keypair = Ed25519Keypair.fromSecretKey(new Uint8Array(wallet));

  const enrollment_object_id =
    "0x8a01cf24865096d16381f085707026a924c63f18ea39f14dec772b363818a1f7";
  const instructor_cap : string =
    "0x70df090e3c838b70905ccbe0086ed7ad97f1695f36e870477b60579f7b7b3daa";
  const cohort =
    "0xe8839db08ebad8badaaf30312f57741796162599bd30188a15c0f1dec2d37a87";
  
  xit("Deploy package", async () => {});

  xit("Create new cohort", async () => {
    const enrollment = new Enrollment(enrollment_object_id, instructor_cap, "testnet");
    await enrollment.create_cohort("Q1").rpc(keypair, {showEffects:true});
  });

  xit("Toggle signups for new cohort", async () => {
    const enrollment = new Enrollment(enrollment_object_id, instructor_cap, "testnet");
    await enrollment.add_cohort_obj(cohort).toggle_signups().rpc(keypair, {showEffects:true});
  });

  xit("enroll new user", async () => {
    const enrollment = new Enrollment(enrollment_object_id, instructor_cap, "testnet");
    await enrollment.add_cohort_obj(cohort).enroll("testgithub").rpc(keypair, {showEffects:true});
  });

  xit("update github", async () => {
    const enrollment = new Enrollment(enrollment_object_id, instructor_cap, "testnet");
    await enrollment.add_cohort_obj(cohort).update("testgithub").rpc(keypair, {showEffects:true});
  });

});
