const { ethers, upgrades } = require('hardhat');
const chalk = require('chalk');

function dim() {
    console.log(chalk.dim.call(chalk, ...arguments))
}

function green() {
    console.log(chalk.green.call(chalk, ...arguments))
}

//Before deployment make sure--
// set current aimax address in liquidity and capsule maker 
// set current star capsule address in liquidity and capsule maker
// set current pair address in liquidity
async function main() {

    const [deployer] = await ethers.getSigners();

    const liquidityWallet = '0xDaEB208684F598c34757Af54Bf7a5D3a64e37e99';
    const rewardWallet = '0xbeCEa30aBf95d38f192efA8C8686CA97bbE6522B';
    const signer = '0x6dd1CEb1Ad247807e814C7Ab7c42C4f5E7857739';
    // const registryAddress = '0xbC13DF9d7E6E8Ef3882202a1AE353A9eDB99b6a5'

    // dim(`Attaching Registry Contract...`);
    // const registryProxy = await ethers.getContractAt('Registry', registryAddress);
    // green(`Attached Registry Contract ${registryAddress}`);
    // await new Promise((resolve) => setTimeout(resolve, 3000));

    dim(`Creating Registry Contract...`);
    const registry = await ethers.getContractFactory('Registry');
    const registryProxy = await upgrades.deployProxy(registry, []);
    await registryProxy.waitForDeployment();
    const registryAddress = await registryProxy.getAddress();
    green(`Created Registry Contract ${registryAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    dim(`Creating Liquidity Contract...`);
    const liquidity = await ethers.getContractFactory('LiquidityContract');
    const liquidityProxy = await upgrades.deployProxy(liquidity, [liquidityWallet, registryAddress]);
    await liquidityProxy.waitForDeployment();
    const liquidityAddress = await liquidityProxy.getAddress();
    green(`Created Liquidity Contract ${liquidityAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    dim(`Creating Capsule Maker...`);
    const capsuleMaker = await ethers.getContractFactory('CapsuleMaker');
    const capsuleMakerProxy = await upgrades.deployProxy(capsuleMaker, [registryAddress]);
    await capsuleMakerProxy.waitForDeployment();
    const capsuleMakerAddress = await capsuleMakerProxy.getAddress();
    green(`Created Capsule Maker ${capsuleMakerAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.setAuthorizedContract(capsuleMakerAddress, true);
    green(`Set authorized purchase maker to call liquidity contract`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.updateCapsuleMakerContract(capsuleMakerAddress);
    green(`Added Capsule Maker in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.updateLiquidityContract(liquidityAddress);
    green(`Added Liquidity Contract in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.updateRewardWallet(rewardWallet);
    green(`Added Reward Treasury in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.setTrustedSigner(signer, true);
    green(`Set Trusted Signer in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

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