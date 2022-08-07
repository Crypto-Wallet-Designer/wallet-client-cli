const ethers = require("ethers");
const elliptic = require('elliptic');
const ec = new elliptic.ec('secp256k1');
const contract = require("./artifacts/contracts/SampleThreeWallet.sol/SampleThreeWallet.json");
const { program, createCommand} = require('commander');

function getWalletContract(network) {
    const infuraProvider = new ethers.providers.AlchemyProvider(network, process.env.API_KEY);
    const signer = new ethers.Wallet(process.env.SOURCE_WALLET_PRIVATE_KEY, infuraProvider);
    return new ethers.Contract(process.env.CONTRACT_ADDRESS, contract.abi, signer);
}

async function getMsgHash(dest, amount) {
    if (!ethers.utils.isAddress(dest)) { return "You must pass a valid destination address"; }
    const walletContract = getWalletContract(process.env.NETWORK);

    const parsedAmount = ethers.utils.parseEther(amount);
    let nonce = await walletContract.getNonce();
    return await walletContract.hashTransfer(nonce, dest, parsedAmount);
}

function sign(key, msgHash) {
    let privateKey = key.getPrivate("hex");
    let sig = ec.sign(msgHash.substring(2), privateKey, "hex", {canonical: true});
    let arr = sig.r.toArray("little", 32);
    arr = arr.concat(sig.s.toArray("little", 32));
    arr.push(sig.recoveryParam + 27);
    return arr;
}

const fromHexString = (hexString) =>
  Uint8Array.from(hexString.match(/.{1,2}/g).map((byte) => parseInt(byte, 16)));

async function walletTransfer(dest, amount, signatures) {
    const walletContract = getWalletContract(process.env.NETWORK);
    const parsedAmount = ethers.utils.parseEther(amount);

    let sigs = [];
    for (let signature of signatures) {
        sigs.push(Array.from(fromHexString(signature)));
    }

    return await walletContract.transfer(dest, parsedAmount, sigs);
}


async function fundContract(address, signer, amount) {
    if (signer) {
        let tx = await signer.sendTransaction({
            to: address,
            value: ethers.utils.parseEther(amount),
            gasLimit: 50000
        });
        console.log(`tx hash: ${tx.hash}`);
    }
}

async function main() {
    require('dotenv').config()

    program
      .addCommand(
        createCommand("getTransferHash").arguments("destinationAddress amount")
          .description("get tx hash to send <value> eth to <destinationAddress> on <network>"))
      .addCommand(
        createCommand("signHash").arguments("hash")
          .description("sign hash using private key defined by SIGNING_PRIVATE_KEY env var, encodes sig as HEX STRING"))
      .addCommand(
        createCommand("submitSignedTransfer").arguments("destinationAddress amount")
          .requiredOption("--signatures", "signed hash strings, separated by spaces")
          .description("submit transfer command with signed hashes passed as list by --signatures"))
      .addCommand(
        createCommand("fundContract").arguments("amount")
          .description("the contract must have sufficient balance to originate a tx. try sending 0.05 eth if this isn't true"))

    program.parse();

    if (program.args[0] === "getTransferHash") {
        console.log(await getMsgHash(program.args[1], program.args[2]));
    }
    else if (program.args[0] === "signHash") {
        const key = ec.keyFromPrivate(process.env.SIGNING_PRIVATE_KEY);
        const signature = new Uint8Array(sign(key, program.args[1]));
        let hex = Buffer.from(signature).toString('hex');
        console.log(hex);
    }
    else if (program.args[0] === "submitSignedTransfer") {
        let signatures = [];
        const startFrom = program.args.indexOf("--signatures") + 1;
        for(let i = startFrom; i < program.args.length; i++) {
            signatures.push(program.args[i]);
        }
        try {
            let receipt = await walletTransfer(program.args[1], program.args[2], signatures);
            console.log(`tx auth successful. tx receipt: ${receipt.hash}`);
        } catch (e) {
            console.log('tx failed. ensure contract has sufficient balance and signatures are valid.');
        }
    } else if (program.args[0] === "fundContract") {
        const infuraProvider = new ethers.providers.AlchemyProvider(process.env.NETWORK, process.env.API_KEY);
        const signer = new ethers.Wallet(process.env.SOURCE_WALLET_PRIVATE_KEY, infuraProvider);
        await fundContract(process.env.CONTRACT_ADDRESS, signer, program.args[1]);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});