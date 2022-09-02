// ------------------------------------------------------------------------------------------------------------------------
// To Do
// ------------------------------------------------------------------------------------------------------------------------
// 1. Limit the number of free NFT that this contract can create, max supply 


// ------------------------------------------------------------------------------------------------------------------------
// Summary
// ------------------------------------------------------------------------------------------------------------------------
// 1. This particular smart contract is handling the minting, and the permission to mint the free Alex, which is  
// an Free NFT offered by MobiFi to its users in order to enable them to use the gamification feature.
// 2. Each user can Mint only one Free NFT which is going to be stored in a tangany managed wallet.
// 
// License
// SPDX-License-Identifier: MIT


// ------------------------------------------------------------------------------------------------------------------------
// Libraries
// ------------------------------------------------------------------------------------------------------------------------

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


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

contract FreeHunterAlexTestV4 is ERC721, ERC721URIStorage, AccessControl {
    
    // Identify if a particular user has been authorised to mint a MobiFi NFT 
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(string => uint8) existingURIs;

    mapping(address => bool) private hasAlreadyMintedNFT;

    constructor() ERC721("FreeHunterAlexTestV4", "FHATV4") {
        
        // Grants the contract deployer and ADMIN ROLE. Only ADMINS will be able to 
        // grand minting permission to other users 
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

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
    // Heroku is it used as a proxy to communicate with MobiFi backend.
    // Input: 
    // Output: NFT character URL
    // ----------------------------------------------------------------------------------

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://mobifi-nft-metadata-server-3.herokuapp.com/api/v1/nft-metadata/get-nft-metadata-with-token-id/";
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
        require(
            !hasAlreadyMintedNFT[to],
            "ERROR_ADDRESS_ALREADY_MINTED_CHARACTER"
        );
        require(existingURIs[uri] != 1, "ERROR_TOKEN_ALREADY_MINTED");
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        existingURIs[uri] = 1;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        hasAlreadyMintedNFT[to] = true;
        return tokenId;
    }
    
    // ----------------------------------------------------------------------------------
    // Function: Allow user to mint NFT using mobifi mobile app. It will be executed by the 
    //           admin 
    // Input: 1. users wallet address 
    // Output: 1. Grand permission to mint NFT 
    // ----------------------------------------------------------------------------------
    function grantMinterRole(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, to);
    }

    // ----------------------------------------------------------------------------------
    // Function: Remove minting role  
    // Input: 1. users wallet address 
    // Output: 1. remove permission to mint the Free NFT 
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
    // Function: Burn an NFT character 
    // Input:   
    // Output: 
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
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // ----------------------------------------------------------------------------------
    // Function: Number of NFT minted by user 
    // Input: 
    // Output: 
    // ----------------------------------------------------------------------------------  
    
    function count() public view returns (uint256) {
        return _tokenIds.current();
    }

    function isContentOnwed(string memory uri) public view returns (bool) {
        return existingURIs[uri] == 1;
    }


    // ----------------------------------------------------------------------------------
    // Function: Prevent the same user minting a second FREE NFT, only one 
    // is allowed per user 
    // Input: 1. wallet address 
    // Output: 
    // ----------------------------------------------------------------------------------  
    
    function addressHasMintedNFT(address userAddress)
        public
        view
        returns (bool)
    {
        return hasAlreadyMintedNFT[userAddress];
    }
}
