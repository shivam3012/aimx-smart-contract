const { ethers, upgrades } = require('hardhat');
const chalk = require('chalk');

function dim() {
    console.log(chalk.dim.call(chalk, ...arguments))
}

function green() {
    console.log(chalk.green.call(chalk, ...arguments))
}

async function main() {
    const [deployer] = await ethers.getSigners();

    const artifactName = 'MillionMeme'
    const contractAddress = '0x22C74D9400088F7F35eC7C591Bbd1945A14b69bc'

    const customNft = await ethers.getContractFactory(artifactName);

    console.log("customNft", customNft)

    console.log(`Upgrading ${artifactName}...`);
    await upgrades.upgradeProxy(contractAddress, customNft);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    });