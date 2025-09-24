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

    //4 miilion
    const initialSupply = '138000000000000000000000000';
    const initialMintAddress = '0x02aa8F4069fAE78889356DC1A1756C40b7887C14';

    dim(`Creating AiMax...`);
    const aimx = await ethers.getContractFactory('AiMAX');
    const aimxProxy = await upgrades.deployProxy(aimx, [initialSupply, initialMintAddress]);
    await aimxProxy.waitForDeployment();
    const aimxAddress = await aimxProxy.getAddress();
    green(`Created AiMax ${aimxAddress}`);

    dim(`Creating Registry Contract...`);
    const registry = await ethers.getContractFactory('Registry');
    const registryProxy = await upgrades.deployProxy(registry, []);
    await registryProxy.waitForDeployment();
    const registryAddress = await registryProxy.getAddress();
    green(`Created Registry Contract ${registryAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    dim(`Creating Star Capsule...`);
    const starCapsule = await ethers.getContractFactory('StarsCapsule');
    const starCapsuleProxy = await upgrades.deployProxy(starCapsule, ["staradam", "staradam", "0x"]);
    await starCapsuleProxy.waitForDeployment();
    const starCapsuleAddress = await starCapsuleProxy.getAddress();
    green(`Created Star Capsule ${starCapsuleAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    // dim(`Creating Check Contract...`);
    // const checkNft = await ethers.getContractFactory('Check');
    // const checkNftProxy = await upgrades.deployProxy(checkNft, []);
    // await checkNftProxy.waitForDeployment();
    // const checkNftAddress = await checkNftProxy.getAddress();
    // green(`Created Check Contract ${checkNftAddress}`);


    //-------Pending-- need to do manually
    //1.whitelist uniswap v2 address
    //2.whitelist liquidity address
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    });