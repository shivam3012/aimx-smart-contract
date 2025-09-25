// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AiMAX.sol";
import "./uniswap/SwapAlgorithm.sol";
import "./uniswap/ISwapRouter.sol";
import "./uniswap/IQuoter.sol";
import "./Registry.sol";

contract LiquidityContract is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public constant UNISWAP_ROUTER_V3 =
        0x2626664c2603336E57B271c5C0b26F421741e481;

    address public constant UNISWAP_ROUTER_V2 =
        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;

    address public constant PAIR = 0x7bD28DEAAe1c78ce8aD3f9dD627F4f7d72B3481e;

    address public constant AIMX = 0x66D89ab6B0e953E7abc0E00715aBbf7054ccC34a;
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant QUOTER = 0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a;
    uint256 public sellPer;
    uint256 public buyPer;
    uint256 public liquidityPer;
    uint256 public rewardPer;
    address public liquidityWallet;
    address public registry;

    function initialize(
        address _liquidityWallet,
        address _registry
    ) external initializer {
        __Ownable_init(_msgSender());
        //66%
        sellPer = 66;
        //88%-- reward is 12%
        buyPer = 88;
        //12%
        rewardPer = 12;
        //70%
        liquidityPer = 70;
        liquidityWallet = _liquidityWallet;
        registry = _registry;
        IERC20(USDC).forceApprove(UNISWAP_ROUTER_V2, type(uint128).max);
        IERC20(USDC).forceApprove(UNISWAP_ROUTER_V3, type(uint128).max);
        IERC20(AIMX).forceApprove(UNISWAP_ROUTER_V2, type(uint128).max);
    }

    function approveThis(address _token, address _addr) external onlyOwner {
        IERC20(_token).forceApprove(_addr, type(uint128).max);
    }

    function performLiqudityOp(
        uint256 _ethIn
    ) external payable returns (uint256, uint256 _reward12) {
        require(
            Registry(registry).authorizedContract(_msgSender()),
            "LiquidityContract: Only authorized"
        );

        //get user actual aimx given with eth input
        address[] memory _path = new address[](2);

        _path[0] = AIMX;
        _path[1] = WETH;

        //sell 66% aimx for eth
        //66% of eth in terms of aimx will be sold
        //means aimx is sold to get eth
        uint256 _sellAimxAmount = SwapAlgorithm.getInputAmount(
            ((_ethIn * sellPer) / 100),
            _path,
            UNISWAP_ROUTER_V2
        );

        //mint aimx to sell from coin contract
        AiMAX(payable(AIMX)).mintTokenSupply(address(this), _sellAimxAmount);

        uint256 _ethOutput = SwapAlgorithm._swapTokenForEth(
            _sellAimxAmount,
            address(this),
            UNISWAP_ROUTER_V2,
            _path
        );

        //add liquidity-send lp to reward contract
        uint256 _aimxForLp = SwapAlgorithm._secondTokenAmountForLp(
            (_ethOutput * liquidityPer) / 100,
            PAIR,
            WETH,
            AIMX
        );

        //mint fpr lp from coin contract
        AiMAX(payable(AIMX)).mintTokenSupply(address(this), _aimxForLp);

        IUniswapV2Router(UNISWAP_ROUTER_V2).addLiquidityETH{value: _ethOutput}(
            AIMX,
            _aimxForLp,
            0,
            0,
            liquidityWallet,
            block.timestamp + 1800
        );

        //buy 88% aimx with eth
        uint256 _buyEthAmt = ((_ethIn * buyPer) / 100);
        _path[0] = WETH;
        _path[1] = AIMX;
        //swap and send purchased aimx capsule contract
        uint256 _aimxPurchased = SwapAlgorithm._swapEth(
            _buyEthAmt,
            _msgSender(),
            UNISWAP_ROUTER_V2,
            _path
        );

        //send 12% or remaining Eth amount in rewards contracts
        _reward12 = _ethIn - _buyEthAmt;
        payable(Registry(registry).rewardWallet()).transfer(_reward12);
        return (_aimxPurchased, _reward12);
    }

    function updateSellPer(uint256 _sellPer) external onlyOwner {
        sellPer = _sellPer;
    }

    function updateBuyPer(uint256 _buyPer) external onlyOwner {
        buyPer = _buyPer;
    }

    function updateRewardPer(uint256 _rewardPer) external onlyOwner {
        rewardPer = _rewardPer;
    }

    function updateLiquidityPer(uint256 _liquidityPer) external onlyOwner {
        liquidityPer = _liquidityPer;
    }

    function setLiquidityAddress(address _liquidityWallet) external onlyOwner {
        liquidityWallet = _liquidityWallet;
    }

    function setRegistry(address _registry) external onlyOwner {
        registry = _registry;
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
