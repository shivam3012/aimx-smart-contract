// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "./Registry.sol";

contract GiftCard is
    ERC1155SupplyUpgradeable,
    ERC1155BurnableUpgradeable,
    OwnableUpgradeable
{
    using Strings for string;

    event GiftCardPurchased(
        address _receiver,
        string[] _uri,
        uint256[] _usd,
        uint256[] _quantity,
        uint256[] _tokenIds
    );

    event GiftCardsRedeemed(
        address user,
        uint256 usdAmount,
        uint256[] tokenIds,
        uint256[] quantities
    );

    uint256 public currentTokenID;
    bool public isPurchaseActive;
    // token name
    string public name;
    // token symbol
    string public symbol;
    address public registry;

    mapping(uint256 => string) private _tokenUri;
    //map usd of gift card corresponding to token id
    mapping(uint256 => uint256) private giftCardValue;

    modifier whenMintActive() {
        require(isPurchaseActive, "GiftCard: Purchase not active");
        _;
    }

    //creator or whitelisted
    modifier onlyAllowed() {
        require(
            Registry(registry).whitelisted(_msgSender()),
            "GiftCard: Only allowed wallets"
        );
        _;
    }

    function initialize(
        string calldata _uri,
        address _registry
    ) external initializer {
        __Ownable_init(_msgSender());
        __ERC1155_init(_uri);
        __ERC1155Burnable_init();
        name = "Pop Gift Cards";
        symbol = "POPGC";
        registry = _registry;
        isPurchaseActive = true;
    }

    /**
     * @dev Creates a new gift card type and assigns _initialSupply to an address and transfer to receiver
     * @param _uri Optional URI for this token type
     * @param _usd usd of gift card
     * @param _quantity quantity for this token type
     * @param _receiver Creator address for this token type
     * @return The newly created token ID
     */
    function distributeGiftCard(
        address _receiver,
        string calldata _uri,
        uint256 _usd,
        uint256 _quantity
    ) public whenMintActive onlyAllowed returns (uint256) {
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

        _tokenUri[_id] = _uri;
        giftCardValue[_id] = _usd;
        _mint(_receiver, _id, _quantity, "0x");
        return _id;
    }

    /**
     * @dev Bulk Creates a new gift card type and assigns _initialSupply to an address and transfer to user
     * @param _uri Optional URI for this token type
     * @param _usd usd of gift card
     * @param _quantity Quantity for this token type
     * @param _receiver Creator address for this token type
     * @return _idList The newly created token ID
     */
    function bulkDistribute(
        address _receiver,
        string[] calldata _uri,
        uint256[] calldata _usd,
        uint256[] calldata _quantity
    ) external whenMintActive returns (uint256[] memory _idList) {
        _idList = new uint256[](_uri.length);
        for (uint256 i = 0; i < _quantity.length; i++) {
            _idList[i] = distributeGiftCard(
                _receiver,
                _uri[i],
                _usd[i],
                _quantity[i]
            );
        }
        emit GiftCardPurchased(_receiver, _uri, _usd, _quantity, _idList);
        return _idList;
    }

    function redeemGiftCards(
        uint256[] calldata _tokenIds,
        uint256[] calldata _quantities,
        uint256 _usdValue,
        address _user
    ) external onlyAllowed {
        burnBatch(_user, _tokenIds, _quantities);
        emit GiftCardsRedeemed(_user, _usdValue, _tokenIds, _quantities);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override(ERC1155SupplyUpgradeable, ERC1155Upgradeable) {
        ERC1155SupplyUpgradeable._update(from, to, ids, values);
    }

    /**
     * Override isApprovedForAll for whitelisted accounts to enable burn on redemption.
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view override returns (bool isOperator) {
        if (Registry(registry).whitelisted(_operator)) {
            return true;
        }
        return ERC1155Upgradeable.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev get current token balance of user
     * @param account address of user
     */
    function tokenAvailable(
        address account
    ) public view virtual returns (uint256[] memory) {
        uint256[] memory _tokenBalances = new uint256[](currentTokenID);
        _tokenBalances[0] = 0;
        for (uint256 i = 1; i < currentTokenID; i++) {
            _tokenBalances[i] = balanceOf(account, i);
        }
        return _tokenBalances;
    }

    function setTokenUri(
        uint256 _id,
        string calldata _uri
    ) external onlyAllowed {
        _tokenUri[_id] = _uri;
    }

    function uri(
        uint256 _id
    ) public view virtual override returns (string memory) {
        require(_exists(_id), "GiftCard: Non existent NFT");
        return _tokenUri[_id];
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return giftCardValue[_id] != 0;
    }

    /**
     * @dev calculates the next token ID based on value of currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenID() private view returns (uint256) {
        return currentTokenID + 1;
    }

    /**
     * @dev increments the value of currentTokenID
     */
    function _incrementTokenTypeId() private {
        currentTokenID++;
    }

    //////
    /////Owner Functions
    /////
    function startPurchase() external onlyOwner {
        isPurchaseActive = true;
    }

    function stopPurchase() external onlyOwner whenMintActive {
        isPurchaseActive = false;
    }

    function updateRegistry(address _registry) external onlyOwner {
        registry = _registry;
    }
}
