# Wallet CLI Client
This is a cli client for wallets deployed by the optimization frontend found at https://crypto-wallet-designer.github.io/crypto-key-calculator/.

This client *ONLY* supports simple transfers between accounts. Further work is required to 
support more generic interactions with smart contracts. Please feel free to expand
the client and submit a PR for review.

# Setup --->

## Clone The Repo
`git clone https://github.com/Crypto-Wallet-Designer/wallet-client-cli.git`

## Install Dependencies
`npm i`

## Compile Contracts
`npx hardhat compile`
*note this may try to install hardhat on your machine. that's expected and ok*

## Configure .env
The client assumes certain environment variables are appropriately set.
These include:
1. SOURCE_WALLET_PRIVATE_KEY: *the private key of the wallet you intend to transfer from*
2. SIGNING_PRIVATE_KEY: *the private key of the wallet you want to sign the transfer hash with. this should correspond to one of the public keys you initialized as an authorized key on your contract*
3. CONTRACT_ADDRESS: *the address of the deployed contract*
4. API_KEY: *your Alchemy (https://www.alchemy.com/) API key*
5. NETWORK: *target network (ex: goerli)*

If you place these keys in a `.env` file, they will be automatically loaded.

Feel free to run `cp .env.example .env` and fill in the values.

# Usage --->

## 1. Fund Contract 
If you just deployed your contract, you will need to first fund it so it can pay gas and transfer funds from your wallet.

Run `node main.js fundContract <amount>`

Example: `node main.js fundContract 0.005` **note units are in ether**

## 2. Generate Transfer Hash
The contract authorizes a transfer based on signed hashes of the
transfer.

To satisfy this condition, you'll need to first generate the transfer hash.

Run `node main.js getTransferHash <destination_address> <amount>`, 

where `destination_address` is the 
address you intend to send `amount` eth to.

Example: `node main.js getTransferHash 0xe20cB814f17B7d1102900fF3FA1b9CAFbF76b7C0 0.005`

## 3. Sign Hash
You'll need to get signatures on the hash generated in Step 2 according
to the auth scheme of your contract.

To sign the hash from Step 2 with the private key specified in the `SIGNING_PRIVATE_KEY` 
env variable, run:

`node main.js signHash <hash>`

Example: `node main.js signHash 0xa789f1d28c0c0ec8f3b5a020a46cbcf8377cab328eedb194f69b467a710adc11`

## 4. Submit Signed Transfer Tx
Once you've accumulated sufficient signed hashes (based on the auth scheme of your contract),
you can submit them all as an authorized transaction with:

`node main.js submitSignedTransfer <destination_address> <amount> --signatures <1> <2> ...`

**NOTE THE DESTINATION ADDRESS AND AMOUNT MUST EXACTLY MATCH THE ARGUMENTS YOU PASSED IN STEP 2 TO GENERATE THE HASH**

**Also note that if you interacted with the contract between generating the hash and submitting
the signatures, it'll fail for an invalid nonce**

Example: `node main.js submitSignedTransfer 0xe20cB814f17B7d1102900fF3FA1b9CAFbF76b7C0 0.005 --signatures 92dd73dc22030ac3fb084ec700a4b402869a600ae2fa11a570244cdfa14576ce70365f513950d9266de8d2cc873a209f52a61fd6eb29d0df535018b32488c3161b d712c8e6380bc5fc6b5935ed4ad68d7078a471a48f3337506d0a314022af46487f6c9425c17a33cea04519f23a7b9073194b562082aae09b87c0d2e95d7890e81b`

# Help --->
You can always run `node main.js help` to see usage options.

You can also dm Kristian on Twitter: https://twitter.com/kayolord