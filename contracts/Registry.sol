// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Registry is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    //12% usdc reward stored
    uint256 public rewardsCollected;
    address public companyWallet;
    address public rewardWallet;
    address public liquidityContrAddr;
    address public capsuleMakerAddr;
    address public whitelabelCapsuleMakerAddr;

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

    function updateCapsuleMakerContract(
        address _capsuleMakerAddr
    ) external onlyOwner {
        capsuleMakerAddr = _capsuleMakerAddr;
    }

    function updateWhitelabelCapsuleMakerContract(
        address _whitelabelCapsuleMakerAddr
    ) external onlyOwner {
        whitelabelCapsuleMakerAddr = _whitelabelCapsuleMakerAddr;
    }

    function updateCompanyWallet(address _companyWallet) external onlyOwner {
        companyWallet = _companyWallet;
    }

    function updateRewardWallet(address _rewardWallet) external onlyOwner {
        rewardWallet = _rewardWallet;
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
