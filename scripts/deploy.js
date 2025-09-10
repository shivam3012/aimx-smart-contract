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
    const initialSupply = '40000000';
    const initialMintAddress = '0x812C6d306590F413DEF57f9eDF033bE716161bFD';

    dim(`Creating Million Meme...`);
    const millionMeme = await ethers.getContractFactory('MillionMeme');
    const millionMemeProxy = await upgrades.deployProxy(millionMeme,
        [initialSupply, initialMintAddress]);
    await millionMemeProxy.waitForDeployment();
    const pop404Address = await millionMemeProxy.getAddress();
    green(`Created Million Meme ${pop404Address}`);

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