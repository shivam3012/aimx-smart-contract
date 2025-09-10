// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MillionMeme.sol";
import "./LiquidityContract.sol";
import "./uniswap/SwapAlgorithm.sol";
import "./Registry.sol";

contract WhitelabelPurchaseMaker is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct PurchaseData {
        address user;
        uint256 aimxStaked;
        address l1;
        address l2;
        uint256 referralAimx;
        address creator;
        uint256 creatorAimx;
        uint256 companyAimx;
        uint256 nftStaked;
    }

    event Purchased(PurchaseData _purchase);

    address public constant UNISWAP_ROUTER_V2 =
        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;

    address public constant AIMX = 0x22C74D9400088F7F35eC7C591Bbd1945A14b69bc;
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    //20%
    uint256 public referralPer;
    address public registry;

    function initialize(address _registry) external initializer {
        __Ownable_init(_msgSender());
        registry = _registry;
        referralPer = 2000;
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
        uint256 _aimxPurchasing,
        uint256 _amount,
        uint256 _nftCount
    ) public {
        IERC20(USDC).safeTransferFrom(_msgSender(), address(this), _amount);
        _stakeApp(
            _msgSender(),
            _creator,
            _l1,
            _l2,
            _aimxPurchasing,
            _amount,
            _nftCount
        );
    }

    // buy the coins with matic
    function buyWithEth(
        address _creator,
        address _l1,
        address _l2,
        uint256 _aimxPurchasing,
        uint256 _amount,
        uint256 _nftCount
    ) external payable {
        _amount = _convertUsdcFromEth();
        _stakeApp(
            _msgSender(),
            _creator,
            _l1,
            _l2,
            _aimxPurchasing,
            _amount,
            _nftCount
        );
    }

    function _stakeApp(
        address _who,
        address _creator,
        address _l1,
        address _l2,
        uint256 _aimxPurchasing,
        uint256 _usdcAmt,
        uint256 _nftCount
    ) internal {
        //do the algorithm
        (uint256 _aimxStake, , uint256 _usdcRewards) = LiquidityContract(
            Registry(registry).liquidityContrAddr()
        ).performLiqudityOp(_usdcAmt);
        Registry(registry).setRewardCollected(_usdcRewards);

        uint256 _aimxPurchaser = _nftCount * MillionMeme(AIMX).getUnit();
        uint256 _aimxReferral = ((_aimxStake - _aimxPurchaser) * referralPer) /
            10000;
        uint256 _aimxCreator = (_aimxStake - _aimxPurchaser) - (_aimxReferral * 2);
        //calculate extra aimx if any
        // uint256 _aimxCompany = _aimxStake -
        //     _aimxPurchaser -
        //     (_aimxReferral * 2) -
        //     _aimxCreator;

        uint256 _aimxCompany = 0;

        IERC20(AIMX).safeTransfer(_who, _aimxPurchaser);
        IERC20(AIMX).safeTransfer(_l1, _aimxReferral);
        IERC20(AIMX).safeTransfer(_l2, _aimxReferral);
        IERC20(AIMX).safeTransfer(_creator, _aimxCreator);
        // if (_aimxCompany > 0) {
        //     IERC20(AIMX).safeTransfer(
        //         Registry(registry).companyWallet(),
        //         _aimxCompany
        //     );
        // }

        emit Purchased(
            PurchaseData(
                _who,
                _aimxPurchaser,
                _l1,
                _l2,
                _aimxReferral,
                _creator,
                _aimxCreator,
                _aimxCompany,
                _nftCount
            )
        );
    }

    function _convertUsdcFromEth() internal returns (uint256) {
        require(
            msg.value > 0,
            "WhitelabelPurchaseMaker: Must pass non 0 ETH amount"
        );

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
     *   ------------------Getter inteface for user---------------------
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
