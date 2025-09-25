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

    const liquidityWallet = '0x02aa8F4069fAE78889356DC1A1756C40b7887C14';
    const companyWallet = '0x02aa8F4069fAE78889356DC1A1756C40b7887C14';
    const rewardWallet = '0x02aa8F4069fAE78889356DC1A1756C40b7887C14';
    const signer = '0xaA5330C23E9c768eD997D193C4458396aaC1e9d2';
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
    const liqidityProxy = await upgrades.deployProxy(liquidity, [liquidityWallet, registryAddress]);
    await liqidityProxy.waitForDeployment();
    const liquidityAddress = await liqidityProxy.getAddress();
    green(`Created Liquidity Contract ${liquidityAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    dim(`Creating Capsule Maker...`);
    const capsuleMaker = await ethers.getContractFactory('CapsuleMaker');
    const capsuleMakerProxy = await upgrades.deployProxy(capsuleMaker, [registryAddress]);
    await capsuleMakerProxy.waitForDeployment();
    const capsuleMakerAddress = await capsuleMakerProxy.getAddress();
    green(`Created Capsule Maker ${capsuleMakerAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.updateCapsuleMakerContract(capsuleMakerAddress);
    green(`Added Capsule Maker in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.setAuthorizedContract(capsuleMakerAddress, true);
    green(`Set authorized purchase maker to call liquidity contract`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.updateLiquidityContract(liquidityAddress);
    green(`Added Liquidity Contract in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.updateRewardWallet(rewardWallet);
    green(`Added Reward Treasury in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.updateRewardWallet(companyWallet);
    green(`Added Company Treasury in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.setTrustedSigner(signer, true);
    green(`Set Trusted Signer in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));
}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    });