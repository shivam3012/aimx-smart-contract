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

    const artifactName = 'LiquidityContract'
    const contractAddress = '0xAd1718C61470282E131dEa70B53Ff46CaEEFE9Ad'

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