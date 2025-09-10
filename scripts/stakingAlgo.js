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

    dim(`Creating Registry Contract...`);
    const registry = await ethers.getContractFactory('Registry');
    const registryProxy = await upgrades.deployProxy(registry, [companyWallet]);
    await registryProxy.waitForDeployment();
    const registryAddress = await registryProxy.getAddress();
    green(`Created Registry Contract ${registryAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    dim(`Creating Reward Treasury Contract...`);
    const rewardTreasury = await ethers.getContractFactory('RewardContract');
    const rewardTreasuryProxy = await upgrades.deployProxy(rewardTreasury, [registryAddress]);
    await rewardTreasuryProxy.waitForDeployment();
    const rewardTreasuryAddress = await rewardTreasuryProxy.getAddress();
    green(`Created Reward Treasury Contract ${rewardTreasuryAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.updateRewardTreasury(rewardTreasuryAddress);
    green(`Added Reward Treasury in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    dim(`Creating Purchase Maker...`);
    const purchaseMaker = await ethers.getContractFactory('PurchaseMaker');
    const purchaseMakerProxy = await upgrades.deployProxy(purchaseMaker, [registryAddress]);
    await purchaseMakerProxy.waitForDeployment();
    const purchaseMakerAddress = await purchaseMakerProxy.getAddress();
    green(`Created Purchase Maker ${purchaseMakerAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.updatePurchaseMakerContract(purchaseMakerAddress);
    green(`Added Purchase Maker in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.setAuthorizedContract(purchaseMakerAddress, true);
    green(`Set authorized purchase maker to call liquidity contract`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    dim(`Creating Whitelabel Purchase Maker...`);
    const whitelabelPurchaseMaker = await ethers.getContractFactory('WhitelabelPurchaseMaker');
    const whitelabelPurchaseMakerProxy = await upgrades.deployProxy(whitelabelPurchaseMaker, [registryAddress]);
    await whitelabelPurchaseMakerProxy.waitForDeployment();
    const whitelabelPurchaseMakerAddress = await whitelabelPurchaseMakerProxy.getAddress();
    green(`Created Whitelabel Purchase Maker ${whitelabelPurchaseMakerAddress}`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.updateWhitelabelPurchaseMakerContract(whitelabelPurchaseMakerAddress);
    green(`Added Whitelabel Purchase Maker in Registry`);
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await registryProxy.setAuthorizedContract(whitelabelPurchaseMakerAddress, true);
    green(`Set authorized whitelabel purchase maker to call liquidity contract`);
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

}

main()
    .then(() => process.exit())
    .catch(error => {
        console.error(error);
        process.exit(1);
    });