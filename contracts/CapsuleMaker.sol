// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LiquidityContract.sol";
import "./uniswap/SwapAlgorithm.sol";
import "./Registry.sol";

contract CapsuleMaker is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct PurchaseData {
        address user;
        uint256 aimxBuy;
        address l1;
        address l2;
        uint256 referralAimx;
        address creator;
        uint256 creatorAimx;
        uint256 companyAimx;
        uint256 nftIn;
    }

    event Purchased(PurchaseData _purchase);

    address public constant UNISWAP_ROUTER_V2 =
        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;

    address public constant AIMX = 0x22C74D9400088F7F35eC7C591Bbd1945A14b69bc;
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    address public registry;
    //5%
    uint256 public referralPer;
    //2%
    uint256 public creatorPer;

    function initialize(address _registry) external initializer {
        __Ownable_init(_msgSender());
        registry = _registry;
        referralPer = 500;
        creatorPer = 200;
        IERC20(USDC).forceApprove(UNISWAP_ROUTER_V2, type(uint128).max);
        IERC20(AIMX).forceApprove(UNISWAP_ROUTER_V2, type(uint128).max);
    }

    function approveThis(address _token, address _addr) external onlyOwner {
        IERC20(_token).forceApprove(_addr, type(uint128).max);
    }

    // buy the coins only with usdc
    function buyWithUsdc(
        address _creator,
        address _l1,
        address _l2,
        uint256 _amount,
        uint256 _nftCount
    ) public {
        IERC20(USDC).safeTransferFrom(_msgSender(), address(this), _amount);
        _buy(_creator, _l1, _l2, _amount, _nftCount);
    }

    // buy the coins with matic
    function buyWithEth(
        address _creator,
        address _l1,
        address _l2,
        uint256 _amount,
        uint256 _nftCount
    ) external payable {
        _amount = _convertUsdcFromEth();
        _buy(_creator, _l1, _l2, _amount, _nftCount);
    }

    function _buy(
        address _creator,
        address _l1,
        address _l2,
        uint256 _usdcAmt,
        uint256 _nftCount
    ) internal {
        (
            uint256 _aimxBuy,
            uint256 _aimxOriginalReceive,
            uint256 _usdcRewards
        ) = LiquidityContract(Registry(registry).liquidityContrAddr())
                .performLiqudityOp(_usdcAmt);

        Registry(registry).setRewardCollected(_usdcRewards);

        uint256 _extraAimx;
        if (_aimxBuy > _aimxOriginalReceive) {
            _aimxBuy = _aimxOriginalReceive;
            //send extraAimx to company wallet
            _extraAimx = _aimxBuy - _aimxOriginalReceive;
            if (_extraAimx > 0) {
                IERC20(AIMX).safeTransfer(
                    Registry(registry).companyWallet(),
                    _extraAimx
                );
            }
        }

        uint256 _aimxReferral = (_aimxBuy * referralPer) / 10000;
        IERC20(AIMX).safeTransfer(_l1, _aimxReferral);
        IERC20(AIMX).safeTransfer(_l2, _aimxReferral);

        uint256 _aimxCreator;
        if (_creator != address(0)) {
            _aimxCreator = (_aimxBuy * creatorPer) / 10000;
            IERC20(AIMX).safeTransfer(_creator, _aimxCreator);
        }

        emit Purchased(
            PurchaseData(
                _msgSender(),
                _aimxBuy,
                _l1,
                _l2,
                _aimxReferral,
                _creator,
                _aimxCreator,
                _extraAimx,
                _nftCount
            )
        );
    }

    function _convertUsdcFromEth() internal returns (uint256) {
        require(msg.value > 0, "PurchaseMaker: Must pass non 0 ETH amount");

        address[] memory _path = new address[](2);
        _path[0] = WETH;
        _path[1] = USDC;

        return
            SwapAlgorithm._swapEth(
                msg.value,
                address(this),
                UNISWAP_ROUTER_V2,
                _path
            );
    }

    /*
     *   ------------------Owner inteface for contract---------------------
     *
     */

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
