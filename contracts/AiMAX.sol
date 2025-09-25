// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Check.sol";

interface ICapsuleMaker {
    function checkTransfer(address from, uint256 amount) external view;
}

contract AiMAX is ERC20BurnableUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public check;
    address public capsuleMaker;
    bool public transferCheck;
    bool public capsuleCheck;

    mapping(address => bool) public protected;
    mapping(address => bool) public allowed;

    modifier onlyAllowed() {
        require(allowed[_msgSender()], "AiMAX: Not allowed");
        _;
    }

    function initialize(
        uint256 _initialSupply,
        address _initial
    ) external initializer {
        __ERC20_init("AiMAX", "AIMX");
        __ERC20Burnable_init();
        __Ownable_init(_msgSender());
        _mint(_initial, _initialSupply);
    }

    function toggleStatus_(
        bool _transferCheck,
        bool _capsuleCheck
    ) external onlyOwner {
        transferCheck = _transferCheck;
        capsuleCheck = _capsuleCheck;
    }

    function setCheck(address _check) external onlyOwner {
        check = _check;
    }

    function setCapsuleMaker(address _capsuleMaker) external onlyOwner {
        capsuleMaker = _capsuleMaker;
    }

    function mint(address addr, uint256 amount) external onlyOwner {
        _mint(addr, amount);
    }

    function mintTokenSupply(
        address addr,
        uint256 amount
    ) external onlyAllowed {
        _mint(addr, amount);
    }

    function burnByOwner(address addr, uint256 amount) external onlyOwner {
        _burn(addr, amount);
    }

    function addToProtectList(address _addr) external onlyOwner {
        protected[_addr] = true;
    }

    function removeFromProtectList(address _addr) external onlyOwner {
        protected[_addr] = false;
    }

    function addToAllowedList(address _addr) external onlyOwner {
        allowed[_addr] = true;
    }

    function removeFromAllowedList(address _addr) external onlyOwner {
        allowed[_addr] = false;
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

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (protected[from] || protected[to]) {
            revert("Locked");
        }
        if (transferCheck) {
            Check(check).checkTransfer(from, to, amount);
        }
        // Check transfer restrictions from CapsuleMaker
        if (capsuleCheck && capsuleMaker != address(0) && from != address(0)) {
            ICapsuleMaker(capsuleMaker).checkTransfer(from, amount);
        }
        super._update(from, to, amount);
    }

    receive() external payable {}
}
