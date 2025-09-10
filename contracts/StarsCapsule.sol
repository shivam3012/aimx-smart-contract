// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract StarsCapsule is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;
    using Strings for uint256;

    uint256 public constant MAX_BATCH_SIZE = 100;
    uint256 public tokenId;
    string public baseURI;

    mapping(address => bool) public allowed;

    /* -------------------- Events -------------------- */
    event BatchMintSingleRecipient(address indexed to, uint256[] tokenIds);
    event BatchMintMultipleRecipients(address[] recipients, uint256[] tokenIds);
    event BatchBurn(uint256[] tokenIds);

    /* -------------------- Modifiers -------------------- */
    modifier onlyAllowed() {
        require(
            allowed[_msgSender()] || _msgSender() == owner(),
            "StarsCapsule: Not allowed"
        );
        _;
    }

    /* -------------------- Initializer -------------------- */
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        __Ownable_init(_msgSender());
        tokenId = 1;
        baseURI = _baseURI;
    }

    /* -------------------- Single Mint / Burn -------------------- */
    function safeMint(address _to) external onlyAllowed {
        require(_to != address(0), "StarsCapsule: Zero address");
        _safeMint(_to, tokenId);
        tokenId++;
    }

    function burn(uint256 _tokenId) external onlyAllowed {
        _burn(_tokenId);
    }

    /* -------------------- Batch Mint / Burn -------------------- */
    /// @notice Batch mint multiple NFTs to the same address
    /// @param _to Address to mint NFTs to
    /// @param _quantity Number of NFTs to mint
    function batchMint(address _to, uint256 _quantity) external onlyAllowed {
        require(_to != address(0), "StarsCapsule: Zero address");
        require(
            _quantity > 0 && _quantity <= MAX_BATCH_SIZE,
            "StarsCapsule: Invalid quantity"
        );

        uint256 currentId = tokenId;
        uint256[] memory mintedTokenIds = new uint256[](_quantity);

        for (uint256 i; i < _quantity; ) {
            _safeMint(_to, currentId);
            mintedTokenIds[i] = currentId;

            unchecked {
                ++currentId;
                ++i;
            }
        }

        tokenId = currentId;
        emit BatchMintSingleRecipient(_to, mintedTokenIds);
    }

    /// @notice Batch burn multiple NFTs
    /// @param _tokenIds Array of token IDs to burn
    function batchBurn(uint256[] calldata _tokenIds) external onlyAllowed {
        uint256 length = _tokenIds.length;
        require(length > 0, "StarsCapsule: Empty tokenIds");
        require(length <= MAX_BATCH_SIZE, "StarsCapsule: Too many tokens");

        for (uint256 i; i < length; ) {
            _burn(_tokenIds[i]);
            unchecked {
                ++i;
            }
        }

        emit BatchBurn(_tokenIds);
    }

    /* -------------------- Admin Helpers -------------------- */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setTokenURI(
        uint256 _tokenId,
        string calldata _tokenURI
    ) external onlyOwner {
        require(
            _ownerOf(_tokenId) != address(0),
            "StarsCapsule: Nonexistent token"
        );
        _setTokenURI(_tokenId, _tokenURI);
    }

    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), _amount);
    }

    function recoverETH(uint256 _amount) external onlyOwner {
        payable(_msgSender()).transfer(_amount);
    }

    function addToAllowedList(address _addr) external onlyOwner {
        allowed[_addr] = true;
    }

    function removeFromAllowedList(address _addr) external onlyOwner {
        allowed[_addr] = false;
    }

    function _burn(
        uint256 _tokenId
    ) internal override(ERC721Upgradeable) {
        super._burn(_tokenId);
    }

    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        require(
            _ownerOf(_tokenId) != address(0),
            "StarsCapsule: Nonexistent token"
        );

        // Check if token has custom URI set via setTokenURI
        string memory _tokenURI = super.tokenURI(_tokenId);

        // If custom URI exists (length > 0), return it
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        // Otherwise, return baseURI + tokenId
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /* -------------------- Fallback -------------------- */
    receive() external payable {}

    fallback() external payable {}
}
