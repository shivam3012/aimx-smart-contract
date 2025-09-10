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

    const registryAddress = '0x583117167281E813E7EcC2474cAc6b1f272bC1A4';

    dim(`Creating Gift Card...`);
    const giftCard = await ethers.getContractFactory('GiftCard');
    const giftCardProxy = await upgrades.deployProxy(giftCard, ["0x", registryAddress]);
    await giftCardProxy.waitForDeployment();
    const giftCardAddress = await giftCardProxy.getAddress();
    green(`Created Gift Card ${giftCardAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    });