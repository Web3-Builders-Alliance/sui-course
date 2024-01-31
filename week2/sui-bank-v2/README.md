# Bank Week 2

### Composibility

In this this weeks bank you will notice that instead of trying to pack multiple responsibilities or concerns into a single module they have been identified and extracted into their own modules. Move gives us modules for a reason and that is to promote modularity and composibility and in doing so cleaner code that is easier to audit and less error prone.

The modules are listed as follows:
- `Bank` - this is the main vault our other modules use.
- `Sui Dollar` - a mock stable coin, shows how to easily create a custom Coin
- `Oracle` - Instead of hardcoding a exchange rate we can use a oracle.
- `AMM` - a Automated Market Maker that utilizes Bank, Sui Dollar and our Oracle.
-  `Lending` - a Lending/Borrow module that utilizes Bank, Sui Dollar and our Oracle.

So as you can see AMM and Lending while every diffrent usecases both make use of the same 3 modules, Bank, Sui Dollar and Oracle! This is the true power of modules and by organizing our code in this way the only thing that limits how you compose things together is limited only by your imagination.

### Oracle

Instead of hard coding an exchange rate we have added a module that uses Switchboard as a oracle service. Switchboard is a very easy to use multi-chain oracle that offers a ton of useful features. For our current project we use it to fetch price feed data but as a service it also allows for secure serverless functions and a secrets server that runs in a Intel SGX secure enclave. This means you can securly store API keys and other private information securly while still allowing their oracles to utilize them on your behalf!

### Challenge

- make LTV and admin fee dynamic and set by the admin with value checks
- improve oracle price assurance (timestamp and value guard)
- whitelist oracle feeds
- test all functions + including error cases
- call all fns via PTBs
