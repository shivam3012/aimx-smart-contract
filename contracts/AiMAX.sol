// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Check.sol";

contract AiMAX is ERC20BurnableUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public check;
    bool public transferCheck;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public allowed;

    modifier onlyAllowed() {
        require(allowed[_msgSender()], "AiMAX: Not whitelisted");
        _;
    }

    function initialize() external initializer {
        __ERC20_init("AiMAX", "AIMX");
        __ERC20Burnable_init();
        __Ownable_init(_msgSender());
        whitelist[_msgSender()] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function toggleStatus_(bool _transferCheck) external onlyOwner {
        transferCheck = _transferCheck;
    }

    function setCheck(address _check) external onlyOwner {
        check = _check;
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

    function addToWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = true;
    }

    function addToAllowedList(address _addr) external onlyOwner {
        allowed[_addr] = true;
    }

    function removeFromAllowedList(address _addr) external onlyOwner {
        allowed[_addr] = false;
    }

    function removeFromWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = false;
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
        if (whitelist[from] || whitelist[to]) {
            if (transferCheck) {
                Check(check).checkTransfer(from, to, amount);
            }
            super._update(from, to, amount);
        } else {
            revert("Locked");
        }
    }
}
