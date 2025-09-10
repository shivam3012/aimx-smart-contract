// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

contract AiMAX is ERC20BurnableUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(address => bool) public whitelist;

    function initialize() external initializer {
        __ERC20_init("AiMAX", "AIMX");
        __ERC20Burnable_init();
        __Ownable_init();
        whitelist[_msgSender()] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address addr, uint256 amount) external onlyOwner {
        _mint(addr, amount);
    }

    function burnByOwner(address addr, uint256 amount) external onlyOwner {
        _burn(addr, amount);
    }

    function addToWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = true;
    }

    function removeFromWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = false;
    }

    function recoverExcessToken(address token, uint256 amount)
        external
        onlyOwner
    {
        IERC20Upgradeable(token).safeTransfer(_msgSender(), amount);
    }

    function recoverETH() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (whitelist[from] || whitelist[to]) {
            super._beforeTokenTransfer(from, to, amount);
        } else {
            revert("Locked");
        }
    }
}
