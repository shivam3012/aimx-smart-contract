// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./uniswap/SwapAlgorithm.sol";
import "./Registry.sol";

contract RewardContract is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using MessageHashUtils for bytes32;

    //type- 1-->usdc || 2-->mnm || 3-->referral_usdc
    event RewardClaimed(address user, uint256 rewardType, uint256 rewardClaim);

    address public constant UNISWAP_ROUTER_V2 =
        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;

    address public constant MNM = 0x22C74D9400088F7F35eC7C591Bbd1945A14b69bc;
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant QUOTER = 0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a;

    address public registry;
    bool claimOpen;

    mapping(address => bool) public trustedSigner;

    modifier canClaim() {
        require(claimOpen, "RewardContract: Not allowed");
        _;
    }

    modifier claimSigned(
        uint256 _rewardClaim,
        uint256 _timestamp,
        bool _signer,
        bytes calldata _signature
    ) {
        require(_rewardClaim > 0, "RewardContract: Nothing to claim");
        _;
        if (_signer) {
            require(
                trustedSigner[
                    signingWallet(
                        _msgSender(),
                        _rewardClaim,
                        _timestamp,
                        _signature
                    )
                ],
                "RewardContract: Not authorized to claim"
            );
        } else {
            require(
                Registry(registry).whitelisted(_msgSender()),
                "RewardContract: Incorrect signer"
            );
        }
    }

    function initialize(address _registry) external initializer {
        __Ownable_init(_msgSender());
        registry = _registry;
        IERC20(USDC).forceApprove(UNISWAP_ROUTER_V2, type(uint128).max);
        IERC20(MNM).forceApprove(UNISWAP_ROUTER_V2, type(uint128).max);
    }

    function claimRewardsUsdc(
        uint256 _rewardClaim,
        uint256 _timestamp,
        bytes calldata _signature
    )
        external
        canClaim
        claimSigned(_rewardClaim, _timestamp, true, _signature)
    {
        //tranfser rewards to user
        IERC20(USDC).safeTransferFrom(
            Registry(registry).rewardWallet(),
            _msgSender(),
            _rewardClaim
        );
        emit RewardClaimed(_msgSender(), 1, _rewardClaim);
    }

    function claimRewardsNative(
        uint256 _rewardClaim,
        uint256 _timestamp,
        bytes calldata _signature
    )
        external
        canClaim
        claimSigned(_rewardClaim, _timestamp, true, _signature)
    {
        IERC20(MNM).safeTransfer(_msgSender(), _rewardClaim);
        emit RewardClaimed(_msgSender(), 2, _rewardClaim);
    }

    function claimRewardsFree(
        address _claimer,
        uint256 _rewardClaim,
        bool _rewardUsdc,
        bytes calldata _signature
    ) external canClaim claimSigned(_rewardClaim, 0, false, _signature) {
        uint256 _rewardType = 1;
        if (!_rewardUsdc) {
            //transfer rewards to user
            IERC20(MNM).safeTransfer(_claimer, _rewardClaim);
            _rewardType = 2;
        } else {
            _sellMnmInternally(_claimer, _rewardClaim);
        }
        emit RewardClaimed(_claimer, _rewardType, _rewardClaim);
    }

    function claimRewardsBoth(
        uint256 _rewardClaim,
        uint256 _timestamp,
        bool _rewardUsdc,
        bytes calldata _signature
    )
        external
        canClaim
        claimSigned(_rewardClaim, _timestamp, true, _signature)
    {
        uint256 _rewardType = 1;
        if (!_rewardUsdc) {
            //transfer rewards to user
            IERC20(MNM).safeTransfer(_msgSender(), _rewardClaim);
            _rewardType = 2;
        } else {
            _sellMnmInternally(_msgSender(), _rewardClaim);
        }
        emit RewardClaimed(_msgSender(), _rewardType, _rewardClaim);
    }

    // function redeemGiftCard(
    //     uint256 _rewardClaim,
    //     uint256 _timestamp,
    //     bool _isUsdc,
    //     bytes calldata _signature
    // )
    //     external
    //     canClaim
    //     claimSigned(_rewardClaim, _timestamp, true, _signature)
    // {
    //     address _treasury = 0x6b380C3f4767a23Ab1cFE6865ca4d4B9fC575A65;
    //     address[] memory _path = new address[](2);
    //     _path[0] = USDC;
    //     _path[1] = MNM;
    //     if (!_isUsdc) {
    //         IERC20(MNM).safeTransfer(
    //             _msgSender(),
    //             IUniswapV2Router(UNISWAP_ROUTER_V2).getAmountsIn(
    //                 _sellAmount,
    //                 _path
    //             )
    //         );
    //     } else {
    //         _sellMnmInternally(
    //             _msgSender(),
    //             IUniswapV2Router(UNISWAP_ROUTER_V2).getAmountsIn(
    //                 _sellAmount,
    //                 _path
    //             )
    //         );
    //     }
    //     emit RewardClaimed(_msgSender(), _rewardType, _rewardClaim);
    // }

    //_type- 1->eth|2->usdc
    function claimReferralRewards(
        uint256 _rewardClaim,
        uint256 _timestamp,
        bytes calldata _signature
    )
        external
        canClaim
        claimSigned(_rewardClaim, _timestamp, true, _signature)
    {
        address _treasury = 0x6b380C3f4767a23Ab1cFE6865ca4d4B9fC575A65;
        IERC20(USDC).safeTransferFrom(_msgSender(), _msgSender(), _rewardClaim);
        emit RewardClaimed(_msgSender(), 3, _rewardClaim);
    }

    function sellMnm(uint256 _sellAmount) external returns (uint256) {
        require(_sellAmount > 0, "RewardContract: Must pass non 0 amount");
        IERC20(MNM).safeTransferFrom(_msgSender(), address(this), _sellAmount);
        return _sellMnmInternally(_msgSender(), _sellAmount);
    }

    function _sellUsdcInternally(
        address _receiver,
        uint256 _sellAmount
    ) internal returns (uint256) {
        address[] memory _path = new address[](2);
        _path[0] = USDC;
        _path[1] = MNM;

        return
            SwapAlgorithm._swap(
                _sellAmount,
                _receiver,
                UNISWAP_ROUTER_V2,
                _path
            );
    }

    function _sellMnmInternally(
        address _receiver,
        uint256 _sellAmount
    ) internal returns (uint256) {
        address[] memory _path = new address[](2);
        _path[0] = MNM;
        _path[1] = USDC;

        return
            SwapAlgorithm._swap(
                _sellAmount,
                _receiver,
                UNISWAP_ROUTER_V2,
                _path
            );
    }

    /*
     *   ------------------Getter inteface for user---------------------
     *
     */

    function signingWallet(
        address _user,
        uint256 _rewardClaim,
        uint256 _timestamp,
        bytes calldata _signature
    ) public view returns (address) {
        bytes32 message = keccak256(
            abi.encode(address(this), _user, _rewardClaim, _timestamp)
        );
        bytes32 ethSignedMessageHash = message.toEthSignedMessageHash();
        return ECDSA.recover(ethSignedMessageHash, _signature);
    }

    function toggleStatusC(bool _status) external onlyOwner {
        claimOpen = _status;
    }

    function setTrustedSigner(
        address _wallet,
        bool _status
    ) external onlyOwner {
        trustedSigner[_wallet] = _status;
    }

    function approveThis(address _token, address _addr) external onlyOwner {
        IERC20(_token).forceApprove(_addr, type(uint128).max);
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
