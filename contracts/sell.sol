// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./uniswap/SwapAlgorithm.sol";
import "./uniswap/ISwapRouter.sol";
import "./uniswap/IQuoter.sol";

contract Sell is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public constant UNISWAP_ROUTER_V2 =
        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;

    address public constant PAIR = 0xd62c3E09F200D3C23538899b50321087B4C91cBA;
    address public constant AIMAX = 0x092833e857e96B52692034E35Ec7a8405E503fBA;
    address public constant WETH = 0x4200000000000000000000000000000000000006;

    function initialize(
    ) external initializer {
        __Ownable_init(_msgSender());
        IERC20(AIMAX).forceApprove(UNISWAP_ROUTER_V2, type(uint128).max);
    }

    function approveThis(address _token, address _addr) external onlyOwner {
        IERC20(_token).forceApprove(_addr, type(uint128).max);
    }

    function sell_op_mevbot(uint256 _ethIn) external payable {
        //get user actual aimax given with eth input
        address[] memory _path = new address[](2);

        _path[0] = WETH;
        _path[1] = AIMAX;
        for (uint256 i = 0; i < 40; i++) {
            SwapAlgorithm._swapEth(
                _ethIn,
                _msgSender(),
                UNISWAP_ROUTER_V2,
                _path
            );
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

    receive() external payable {}
}
