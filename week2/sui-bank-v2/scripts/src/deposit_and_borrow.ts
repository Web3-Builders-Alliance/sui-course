import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keypair, getId } from './utils.js';
import { CoinBalance, PaginatedObjectsResponse, SuiObjectResponse } from '@mysten/sui.js/client';

// This PTB creates an account if the user doesn't have one and deposit the required amount into the bank

(async () => {
	const getAccountForAddress = async (addr: string): Promise<string | undefined> => {
		let hasNextPage = true;
		let nextCursor = null;
		let account = undefined;
		
		while (hasNextPage) {
			const objects: PaginatedObjectsResponse = await client.getOwnedObjects({
			owner: addr,
			cursor: nextCursor,
			options: { showType: true },
			});

			account = objects.data?.find((obj: SuiObjectResponse) => obj.data?.type === `${getId("package")}::bank::Account`);
			hasNextPage = objects.hasNextPage;
			nextCursor = objects.nextCursor;

			if (account !== undefined) break;
		}

		return account?.data?.objectId;
	};

	const getSuiDollarBalance = async (): Promise<CoinBalance> => {
		return await client.getBalance({
			owner: keypair.getPublicKey().toSuiAddress(),
			coinType: `${getId("package")}::sui_dollar::SUI_DOLLAR`,
		});
	}

	try {
		const accountId = await getAccountForAddress(keypair.getPublicKey().toSuiAddress());
		
		const tx = new TransactionBlock();
		
		let account = tx.object(accountId);
		// get the coin to deposit
		const [coin] = tx.splitCoins(tx.gas, [tx.pure(1000)]);

		// if the user has no account, we create one
		if (accountId === undefined) {
			[account] = tx.moveCall({
				target: `${getId("package")}::bank::new_account`,
				arguments: [],
			});
		}
	
		tx.moveCall({
			target: `${getId("package")}::bank::deposit`,
			arguments: [
				tx.object(getId("bank::Bank")),
				account,
				coin,
			],
		});

		// get the Price hot potato
		const [price] = tx.moveCall({
			target: `${getId("package")}::oracle::new`,
			arguments: [
				tx.object("0x84d2b7e435d6e6a5b137bf6f78f34b2c5515ae61cd8591d5ff6cd121a21aa6b7"),
			],
		});

		const [sui_dollar] = tx.moveCall({
			target: `${getId("package")}::lending::borrow`,
			arguments: [
				account,
				tx.object(getId("sui_dollar::CapWrapper")),
				price,
				tx.pure(500),
			],
		});

		tx.transferObjects([sui_dollar], keypair.getPublicKey().toSuiAddress());

		// if the user has no account we transfer it
		if (accountId === undefined) {
			tx.transferObjects([account], keypair.getPublicKey().toSuiAddress());
		}

		const result = await client.signAndExecuteTransactionBlock({
			signer: keypair,
			transactionBlock: tx,
			options: {
				showObjectChanges: true,
			},
			requestType: "WaitForLocalExecution"
		});

		console.log("result: ", JSON.stringify(result, null, 2));

	} catch (e) {
		console.log(e)
	} finally{
		// get the total Sui Dollar Coins for the user
		const sd_bal = await getSuiDollarBalance();
		console.log(sd_bal);
	}
})()