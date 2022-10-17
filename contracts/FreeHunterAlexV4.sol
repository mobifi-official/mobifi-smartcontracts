// ------------------------------------------------------------------------------------------------------------------------
// To Do before mainnet
// ------------------------------------------------------------------------------------------------------------------------
// 1. Limit the number of free NFT that this contract can create, max supply
// 2. What does the function _burn(uint256 tokenId) return ?

// ------------------------------------------------------------------------------------------------------------------------
// Summary
// ------------------------------------------------------------------------------------------------------------------------
// 1. This particular smart contract is handling the minting, and the permission to mint the free Alex, which is
// an Free NFT offered by MobiFi to its users in order to enable them to use the gamification feature.
// 2. Each user can Mint only one Free NFT which is going to be stored in a tangany (MobiFi managed) or metamask (user managed) wallet.
//
// License
// SPDX-License-Identifier: MIT

// ------------------------------------------------------------------------------------------------------------------------
// Libraries
// ------------------------------------------------------------------------------------------------------------------------

pragma solidity ^0.8.4;

// Provides a custruction standard for the ERC721 tokens
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Provides functionality for getting NFT character metadata URL
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Provides all fucntionality for transfering ownership
import "@openzeppelin/contracts/access/Ownable.sol";

// Provided all functionality for access controll (e.g. grand perminssion to mint NFT)
import "@openzeppelin/contracts/access/AccessControl.sol";

// Provides functionality for tracking the number of NFT tokens (e.g. increments)
import "@openzeppelin/contracts/utils/Counters.sol";

// ------------------------------------------------------------------------------------------------------------------------
// Functions
// ------------------------------------------------------------------------------------------------------------------------

// ----------------------------------------------------------------------------------
// Function:
// 1. The first function which is called when the smart contract is triggered.
// It initialises the smart-contact.
// 2. The contract deployer is the person who can grand minting permissions to other users
// Only users with minting permissions can get the Free Alex using the Mobifi mobile app
//
// Input:
// Output:
// ----------------------------------------------------------------------------------

contract MobiFiFreeNFTSmartContract is
    ERC721,
    Ownable,
    ERC721URIStorage,
    AccessControl
{
    // Identify if a particular user has been authorised to mint a MobiFi NFT
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Incremental counter of the number of NFT that have been minted
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Set the max supply for NFT
    uint256 public maxSupply;

    // A key-value pair of Token ID and its URL, prevents minting the same token a second time
    mapping(string => uint8) existingURIs;

    // A list of wallets that have minted a free Alex
    mapping(address => bool) private hasAlreadyMintedNFT;

    bool public paused = false;

    // Metadata base url
    string public uriPrefix = "";

    // Grants the contract deployer an ADMIN ROLE.
    // Only ADMINS will be able to grand minting permission to other users
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        string memory _metadataUri
    ) ERC721(_tokenName, _tokenSymbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        maxSupply = _maxSupply;
        setUriPrefix(_metadataUri);
    }

    // TODO: function to transfer admin role to another wallet

    // ----------------------------------------------------------------------------------
    // Function: It is called internaly by the smart-contract the first time it is compliled
    // Input: 1. A unique hashcode for the smart-contact
    // Output: 1. Boolean
    // ----------------------------------------------------------------------------------
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ----------------------------------------------------------------------------------
    // Function: It returns the URL for the NFT character metadata.
    // Heroku is  used as a proxy to communicate with MobiFi backend. The backend will generate
    // a random NFT id
    // Input:
    // Output: NFT character URL
    // ----------------------------------------------------------------------------------
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // ----------------------------------------------------------------------------------
    // Function: Minting an NFT character
    // Input: 1. Wallet address of the NFT receiver
    //        2. Random NFT token ID
    // Output: 1. Which NFT token ID user gets
    // ----------------------------------------------------------------------------------
    function mintNFT(address to, string memory uri)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 uriUint = st2num(uri);

        require(
            !hasAlreadyMintedNFT[to],
            "ERROR_ADDRESS_ALREADY_MINTED_CHARACTER"
        );
        require(existingURIs[uri] != 1, "ERROR_TOKEN_ALREADY_MINTED");

        require(uriUint < maxSupply, "ERROR_NOT_CORRECT_URI_INPUT");

        uint256 supply = count();
        require(supply < maxSupply, "ALL_NFT_ALREADY_MINTED");

        require(!paused, "CONTRACT_MINTING_PAUSED");
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        existingURIs[uri] = 1;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        hasAlreadyMintedNFT[to] = true;
        return tokenId;
    }

    function st2num(string memory numString) public pure returns (uint256) {
        uint256 val = 0;
        bytes memory stringBytes = bytes(numString);
        for (uint256 i = 0; i < stringBytes.length; i++) {
            uint256 exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint256 jval = uval - uint256(0x30);

            val += (uint256(jval) * (10**(exp - 1)));
        }
        return val;
    }

    // ----------------------------------------------------------------------------------
    // Function: Allow user to mint NFT using mobifi mobile app. It will be executed by the
    //           admin
    // Input: 1. User wallet address
    // Output: 1. Grand permission to mint NFT
    // ----------------------------------------------------------------------------------
    function grantMinterRole(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 supply = count();
        require(supply < maxSupply, "ALL_NFT_ALREADY_MINTED");
        grantRole(MINTER_ROLE, to);
    }

    // ----------------------------------------------------------------------------------
    // Function: Remove minting role
    // Input: 1. User wallet address
    // Output: 1. Remove permission to mint the Free NFT
    // ----------------------------------------------------------------------------------
    function revokeMinterRole(address from)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MINTER_ROLE, from);
    }

    // ----------------------------------------------------------------------------------
    // Function: Check if a particular wallet address has minting role
    // Input: 1. User wallet address
    // Output: 1. TRUE/FLASE
    // ----------------------------------------------------------------------------------
    function checkIfAddressHasMinterRole(address addressToCheck)
        public
        view
        returns (bool)
    {
        return hasRole(MINTER_ROLE, addressToCheck);
    }

    // The following functions are overrides required by Solidity.

    // ----------------------------------------------------------------------------------
    // Function: Removes an NFT character from circulation on the chain
    // Input: 1. Token ID
    // Output: 1. A record on the chain
    // ----------------------------------------------------------------------------------
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    // ----------------------------------------------------------------------------------
    // Function: Gets token id and returns the NFT URI
    // Input: 1. Token ID
    // Output: 2. Full NFT token URI
    // ----------------------------------------------------------------------------------
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return super.tokenURI(_tokenId);
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    // ----------------------------------------------------------------------------------
    // Function: Number of NFT minted by user
    // Input:
    // Output: 1. Current number of all NFTs minted under a specific smart-contract
    // ----------------------------------------------------------------------------------

    function count() public view returns (uint256) {
        return _tokenIds.current();
    }

    // ----------------------------------------------------------------------------------
    // Function: Does an NFT character owned by somebody else. Checks on the chain if an
    // existing URI (i.e. tokend ID) is owned by a wallet address
    // Input: 1. NFT token ID
    // Output: 1. Boolean
    // ----------------------------------------------------------------------------------

    function isContentOnwed(string memory uri) public view returns (bool) {
        return existingURIs[uri] == 1;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    // ----------------------------------------------------------------------------------
    // Function: Prevents the same user minting a second FREE NFT, only one is allowed per user
    // Input: 1. wallet address
    // Output: 1. Boolean
    // ----------------------------------------------------------------------------------

    function addressHasMintedNFT(address userAddress)
        public
        view
        returns (bool)
    {
        return hasAlreadyMintedNFT[userAddress];
    }
}
