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

    address public constant PAIR = 0x080aD650Ce2a7b3D1B579c7eBceB59ea452748dB;

    address public constant AIMX = 0x22C74D9400088F7F35eC7C591Bbd1945A14b69bc;
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
        //42%
        sellPer = 42;
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
        uint256 _usdcIn
    ) external returns (uint256, uint256, uint256 _reward12) {
        require(
            Registry(registry).authorizedContract(_msgSender()),
            "LiquidityContract: Only authorized"
        );
        IERC20(USDC).safeTransferFrom(_msgSender(), address(this), _usdcIn);

        //get user actual aimx given with usdc input
        address[] memory _path = new address[](2);
        _path[0] = USDC;
        _path[1] = AIMX;

        uint256 _aimxOriginalReceive = SwapAlgorithm.getOutputAmount(
            _usdcIn,
            _path,
            UNISWAP_ROUTER_V2
        );

        _path[0] = AIMX;
        _path[1] = USDC;

        //sell 42% aimx for usdc
        //42% of usdc in terms of aimx will be sold
        //means aimx is sold to get usdc
        uint256 _sellAimxAmount = SwapAlgorithm.getInputAmount(
            ((_usdcIn * sellPer) / 100),
            _path,
            UNISWAP_ROUTER_V2
        );

        //mint aimx to sell from coin contract
        AiMAX(AIMX).mintTokenSupply(address(this), _sellAimxAmount);

        uint256 _usdcOutput = SwapAlgorithm._swap(
            _sellAimxAmount,
            address(this),
            UNISWAP_ROUTER_V2,
            _path
        );

        //add liquidity-send lp to reward contract
        uint256 _aimxForLp = SwapAlgorithm._secondTokenAmountForLp(
            (_usdcOutput * liquidityPer) / 100,
            PAIR,
            USDC,
            AIMX
        );

        //mint fpr lp from coin contract
        AiMAX(AIMX).mintTokenSupply(address(this), _aimxForLp);
        SwapAlgorithm._addLiquidity(
            _usdcOutput,
            _aimxForLp,
            USDC,
            AIMX,
            UNISWAP_ROUTER_V2,
            liquidityWallet
        );

        //buy 88% aimx with usdc
        uint256 _buyUsdcAmt = ((_usdcIn * buyPer) / 100);
        _path[0] = USDC;
        _path[1] = AIMX;
        uint256 _aimxBuy = SwapAlgorithm._swap(
            _buyUsdcAmt,
            _msgSender(),
            UNISWAP_ROUTER_V2,
            _path
        );

        //send 12% or remaining usdc amount in rewards contracts
        _reward12 = _usdcIn - _buyUsdcAmt;
        IERC20(USDC).safeTransfer(Registry(registry).rewardWallet(), _reward12);
        return (_aimxBuy, _aimxOriginalReceive, _reward12);
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
}
