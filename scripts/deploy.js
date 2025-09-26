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
    const initialSupply = '240000000000000000000000000';
    const initialMintAddress = '0x7cDD7413039a93973E03ae7eC3A3C66d46EAc268';

    dim(`Creating AiMax...`);
    const aimax = await ethers.getContractFactory('AiMAX');
    const aimaxProxy = await upgrades.deployProxy(aimax, [initialSupply, initialMintAddress]);
    await aimaxProxy.waitForDeployment();
    const aimaxAddress = await aimaxProxy.getAddress();
    green(`Created AiMax ${aimaxAddress}`);

    dim(`Creating Star Capsule...`);
    const starCapsule = await ethers.getContractFactory('StarsCapsule');
    const starCapsuleProxy = await upgrades.deployProxy(starCapsule, ["0x"]);
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


    //TODO on Remix manually
    //star capsule-- add capsule maker in allowed list of star capsule to mint nft
    //aimax contract-- add capusle maker and liquidity contract in allowed list of aimax contract to mint tokens
    //aimax contract-- add capsule maker in aimax contract and toggle capsule check
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    });