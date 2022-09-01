// ------------------------------------------------------------------------------------------------------------------------
// Summary
// ------------------------------------------------------------------------------------------------------------------------
// 1. This particular smart contract is handling the minting, and the permission to mint the free Alex, 
// an NFT which is offered to MobiFi users in order to be able to use the gamification feature offed within the mobile app. 
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
// Function: The first function which is called when the smart contract is triggered. 
// It initialise the smart-contact
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
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
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
    // Function: It returns the URL of the NFT character. The images of the NFT charcaters
    // are stored in Pinata, and Heroku is it used as a proxy to communicate with Pinata.
    // Input: 
    // Output: NFT character URL
    // ----------------------------------------------------------------------------------

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://mobifi-nft-metadata-server-3.herokuapp.com/api/v1/nft-metadata/get-nft-metadata-with-token-id/";
    }

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

    function grantMinterRole(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, to);
    }

    function revokeMinterRole(address from)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MINTER_ROLE, from);
    }

    function checkIfAddressHasMinterRole(address addressToCheck)
        public
        view
        returns (bool)
    {
        return hasRole(MINTER_ROLE, addressToCheck);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function count() public view returns (uint256) {
        return _tokenIds.current();
    }

    function isContentOnwed(string memory uri) public view returns (bool) {
        return existingURIs[uri] == 1;
    }

    function addressHasMintedNFT(address userAddress)
        public
        view
        returns (bool)
    {
        return hasAlreadyMintedNFT[userAddress];
    }
}
