// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Registry is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    //12% usdc reward stored
    uint256 public rewardsCollected;
    address public companyWallet;
    address public rewardTreasury;
    address public liquidityContrAddr;
    address public purchaseMakerAddr;
    address public whitelabelPurchaseMakerAddr;

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public authorizedContract;

    function initialize(address _companyWallet) external initializer {
        __Ownable_init(_msgSender());
        companyWallet = _companyWallet;
    }

    /*
     *   ------------------Getter inteface for user---------------------
     *
     */

    function setRewardCollected(uint256 amount) external {
        require(authorizedContract[_msgSender()], "Registry: Not allowed");
        rewardsCollected += amount;
    }

    function updateLiquidityContract(
        address _liquidityAddr
    ) external onlyOwner {
        liquidityContrAddr = _liquidityAddr;
    }

    function updatePurchaseMakerContract(
        address _purchaseMakerAddr
    ) external onlyOwner {
        purchaseMakerAddr = _purchaseMakerAddr;
    }

    function updateWhitelabelPurchaseMakerContract(
        address _whitelabelPurchaseMakerAddr
    ) external onlyOwner {
        whitelabelPurchaseMakerAddr = _whitelabelPurchaseMakerAddr;
    }

    function updateCompanyWallet(address _companyWallet) external onlyOwner {
        companyWallet = _companyWallet;
    }

    function updateRewardTreasury(address _rewardTreasury) external onlyOwner {
        rewardTreasury = _rewardTreasury;
    }

    function toggleWhitelistStatus(
        address _addr,
        bool _status
    ) external onlyOwner {
        whitelisted[_addr] = _status;
    }

    function setAuthorizedContract(
        address _addr,
        bool _status
    ) external onlyOwner {
        authorizedContract[_addr] = _status;
    }

    function recoverExcessToken(
        address token,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(_msgSender(), amount);
    }

    function recoverETH() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}
