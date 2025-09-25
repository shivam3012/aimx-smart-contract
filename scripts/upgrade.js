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

    const artifactName = 'CapsuleMaker'
    const contractAddress = '0x8Bf06E6e9b40EF9F80C9740fCb94677d1317fa87'

    const customNft = await ethers.getContractFactory(artifactName);

    // console.log("customNft", customNft)

    console.log(`Upgrading ${artifactName}...`);
    await upgrades.upgradeProxy(contractAddress, customNft);
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    });