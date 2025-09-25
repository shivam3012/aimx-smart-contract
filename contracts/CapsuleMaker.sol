// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./LiquidityContract.sol";
import "./uniswap/SwapAlgorithm.sol";
import "./Registry.sol";
import "./StarsCapsule.sol";
import "./AiMAX.sol";

contract CapsuleMaker is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    struct PurchaseData {
        address user;
        uint256 aimxBuy;
        address l1;
        address l2;
        uint256 referralAimx;
        address creator;
        uint256 creatorAimx;
        uint256 nftCount;
        uint256 coinPrice; // Current price when purchased
    }

    struct BuyParams {
        address creator;
        address l1;
        address l2;
        uint256 amount;
        uint256 aimxAmount;
        uint256 nftCount;
    }

    event Purchased(PurchaseData _purchase);

    event TokensUnlocked(
        address indexed user,
        uint256 amount,
        uint256[] nftIds,
        bytes32 basketHash
    );

    address public constant UNISWAP_ROUTER_V2 =
        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address public constant AIMX = 0x66D89ab6B0e953E7abc0E00715aBbf7054ccC34a;
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant StarCapsule =
        0xB564e2A84B69e52F5C49B12842d5E9A66DBcF551;

    address public registry;
    uint256 public referralPer; // 5%
    uint256 public creatorPer; // 2%
    uint256 public basketPrice;
    uint256 public ethPriceTolerance;

    // Track locked tokens per user (backend will manage which tokens belong to which baskets)
    mapping(address => uint256) public lockedTokens;

    modifier onlyAuthorized() {
        require(
            Registry(registry).whitelisted(_msgSender()) ||
                _msgSender() == owner(),
            "CapsuleMaker: Not authorized"
        );
        _;
    }

    function initialize(address _registry) external initializer {
        __Ownable_init(_msgSender());
        __ReentrancyGuard_init();

        registry = _registry;
        referralPer = 500; // 5%
        creatorPer = 200; // 2%
        basketPrice = 250e6; //250$
        ethPriceTolerance = 2e6; //2$

        IERC20(USDC).forceApprove(UNISWAP_ROUTER_V2, type(uint128).max);
        IERC20(AIMX).forceApprove(UNISWAP_ROUTER_V2, type(uint128).max);
    }

    function approveThis(address _token, address _addr) external onlyOwner {
        IERC20(_token).forceApprove(_addr, type(uint128).max);
    }

    // Buy packages with USDC
    function buyWithUsdc(
        BuyParams calldata _params,
        bytes calldata _signature
    ) external nonReentrant {
        _verifySignature(_msgSender(), _params, _signature);
        // Must be multiple of $250
        require(
            _params.amount != 0 &&
                _params.amount >= _params.nftCount * basketPrice,
            "CapsuleMaker: Amount must be multiple of $250"
        );
        IERC20(USDC).safeTransferFrom(
            _msgSender(),
            address(this),
            _params.amount
        );
        uint256 _convertedUsdc = _convertUsdcToEth(_params.amount);
        _buy(
            _params.creator,
            _params.l1,
            _params.l2,
            _convertedUsdc,
            _params.aimxAmount,
            _params.nftCount
        );
    }

    // Buy packages with ETH
    function buyWithEth(
        BuyParams calldata _params,
        bytes calldata _signature
    ) external payable nonReentrant {
        _verifySignature(_msgSender(), _params, _signature);
        require(msg.value > 0, "CapsuleMaker: Must pass non 0 ETH amount");
        address[] memory _path = new address[](2);
        _path[0] = WETH;
        _path[1] = USDC;
        uint256 _estimatedUsdc = SwapAlgorithm.getOutputAmount(
            msg.value,
            _path,
            UNISWAP_ROUTER_V2
        );
        // Check if user sent enough ETH for requested packages
        require(
            _estimatedUsdc >=
                (_params.nftCount * basketPrice) - ethPriceTolerance,
            "CapsuleMaker: Amount must be multiple of $250"
        );
        _buy(
            _params.creator,
            _params.l1,
            _params.l2,
            _params.amount,
            _params.aimxAmount,
            _params.nftCount
        );
    }

    function _buy(
        address _creator,
        address _l1,
        address _l2,
        uint256 _usdcAmt,
        uint256 _aimxAmount,
        uint256 _nftCount
    ) internal {
        // Get current coin price for basket tracking
        uint256 currentCoinPrice = getCurrentCoinPrice();

        (uint256 _aimxBuy, uint256 _ethRewards) = LiquidityContract(
            payable(Registry(registry).liquidityContrAddr())
        ).performLiqudityOp{value: msg.value}(_usdcAmt);

        Registry(registry).setRewardCollected(_ethRewards);

        if (_aimxAmount > _aimxBuy) {
            AiMAX(payable(AIMX)).mintTokenSupply(
                address(this),
                _aimxAmount - _aimxBuy
            );
        }

        uint256 _aimxReferral = (_aimxAmount * referralPer) / 10000;
        AiMAX(payable(AIMX)).mintTokenSupply(_l1, _aimxReferral);
        AiMAX(payable(AIMX)).mintTokenSupply(_l2, _aimxReferral);

        uint256 _aimxCreator;
        if (_creator != address(0)) {
            _aimxCreator = (_aimxAmount * creatorPer) / 10000;
            IERC20(AIMX).safeTransfer(_creator, _aimxCreator);
        }

        // Send swapped tokens directly to user (these will be locked by default)
        IERC20(AIMX).safeTransfer(_msgSender(), _aimxAmount);
        // Add to user's locked tokens (backend will manage baskets)
        lockedTokens[_msgSender()] += _aimxAmount;

        // Mint NFTs
        StarsCapsule(payable(StarCapsule)).batchMint(_msgSender(), _nftCount);

        emit Purchased(
            PurchaseData(
                _msgSender(),
                _aimxAmount,
                _l1,
                _l2,
                _aimxReferral,
                _creator,
                _aimxCreator,
                _nftCount,
                currentCoinPrice
            )
        );
    }

    /// @notice Backend calls this to unlock tokens when user burns NFTs
    /// @param user User address
    /// @param amount Amount of tokens to unlock
    /// @param nftIds NFT IDs that were burned (for event logging)
    /// @param basketHash Hash identifier for the basket (for backend tracking)
    function unlockTokens(
        address user,
        uint256 amount,
        uint256[] calldata nftIds,
        bytes32 basketHash
    ) external onlyAuthorized {
        require(
            lockedTokens[user] >= amount,
            "CapsuleMaker: Insufficient locked tokens"
        );
        // Simply reduce locked tokens - the difference becomes transferable
        lockedTokens[user] -= amount;
        emit TokensUnlocked(user, amount, nftIds, basketHash);
    }

    function _convertUsdcToEth(uint256 _amount) internal returns (uint256) {
        require(_amount > 0, "CapsuleMaker: Must pass non 0 amount");

        address[] memory _path = new address[](2);
        _path[0] = USDC;
        _path[1] = WETH;

        return
            SwapAlgorithm._swapTokenForEth(
                _amount,
                address(this),
                UNISWAP_ROUTER_V2,
                _path
            );
    }

    function _verifySignature(
        address _user,
        BuyParams calldata _params,
        bytes calldata _signature
    ) internal view {
        bytes32 messageHash = keccak256(
            abi.encode(
                _user,
                _params.creator,
                _params.l1,
                _params.l2,
                _params.amount,
                _params.aimxAmount,
                _params.nftCount,
                address(this)
            )
        );
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            messageHash
        );
        address _signer = ethSignedMessageHash.recover(_signature);
        require(
            Registry(registry).trustedSigner(_signer),
            "CapsuleMaker: Invalid signature"
        );
    }

    /// @notice Check if user can transfer tokens (called by AiMAX contract)
    /// @param from From address
    /// @param amount Amount to transfer
    function checkTransfer(address from, uint256 amount) external view {
        // If selling to Uniswap, check if user has enough transferable tokens
        uint256 totalBalance = IERC20(AIMX).balanceOf(from);
        uint256 transferableTokens = totalBalance - lockedTokens[from];

        require(
            transferableTokens >= amount,
            "CapsuleMaker: Cannot sell locked tokens - unlock baskets first"
        );
    }

    /// @notice Get current AiMAX price from Uniswap
    function getCurrentCoinPrice() public view returns (uint256) {
        address[] memory _path = new address[](3);
        _path[0] = AIMX;
        _path[1] = WETH;
        _path[2] = USDC;
        // Price in USDC
        return SwapAlgorithm.getOutputAmount(1e18, _path, UNISWAP_ROUTER_V2);
    }

    // View functions
    function getUserTokenSummary(
        address user
    )
        external
        view
        returns (uint256 locked, uint256 transferable, uint256 total)
    {
        total = IERC20(AIMX).balanceOf(user);
        locked = lockedTokens[user];
        transferable = total - locked; // All non-locked tokens are transferable
    }

    function canSellAmount(
        address user,
        uint256 amount
    ) external view returns (bool) {
        uint256 totalBalance = IERC20(AIMX).balanceOf(user);
        uint256 transferableTokens = totalBalance - lockedTokens[user];
        return transferableTokens >= amount;
    }

    // Admin functions
    function setRegistry(address _registry) external onlyOwner {
        registry = _registry;
    }

    function setReferralPer(uint256 _referralPer) external onlyOwner {
        referralPer = _referralPer;
    }

    function setCreatorPer(uint256 _creatorPer) external onlyOwner {
        creatorPer = _creatorPer;
    }

    function setEthTolerance(uint256 _ethPriceTolerance) external onlyOwner {
        ethPriceTolerance = _ethPriceTolerance;
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
