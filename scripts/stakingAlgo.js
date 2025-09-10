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

    const liquidityWallet = '0xb396f64C52B5C4b7a787b7e3121f7889410EF034';
    const companyWallet = '0xb396f64C52B5C4b7a787b7e3121f7889410EF034';
    const rewardWallet = '0xb396f64C52B5C4b7a787b7e3121f7889410EF034';

    dim(`Creating Registry Contract...`);
    const registry = await ethers.getContractFactory('Registry');
    const registryProxy = await upgrades.deployProxy(registry, [companyWallet]);
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

    await registryProxy.updateLiquidityContract(liquidityAddress);
    green(`Added Liquidity Contract in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.updateRewardWallet(rewardWallet);
    green(`Added Reward Treasury in Registry`);
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

    await registryProxy.setAuthorizedContract(whitelabelCapsuleMakerAddress, true);
    green(`Set authorized whitelabel purchase maker to call liquidity contract`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    });