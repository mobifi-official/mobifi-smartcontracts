// ------------------------------------------------------------------------------------------------------------------------
// Summary
// ------------------------------------------------------------------------------------------------------------------------
// 1. This particular smart contract is handling the minting, and the permission to mint the PAID Alex, which is  
// an NFT offered by MobiFi to its users in order accelerate the earning of reward points (i.e. greenz) after each parking 
// transaction. For example, when a user holds a Free NFT Alex he/she can earn 1 greenz for each dollar spent on parking.
// In contrast when a user holds a paid NFT character each greenz awarded is multiplied by a percentage of 30%
// 
// 2. Each user can mint multiple paid NFT characters, and use a different one every time he/she is parking.
// 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// ------------------------------------------------------------------------------------------------------------------------
// Libraries
// ------------------------------------------------------------------------------------------------------------------------
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


// ------------------------------------------------------------------------------------------------------------------------
// Functions
// ------------------------------------------------------------------------------------------------------------------------

contract PaidHunterAlexTestV1 is ERC721, ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Set the max supply of NFT
    uint256 public constant maxSupply = 1000;

    // ERC20 Token address
    // For instance the token address of MoFi which is used to pay the NFT character 
    IERC20 private tokenAddress;

    // MobiFi wallet address to receive MoFi which are stored in the smart-contract 
    // every time a user mint a paid NFT offered by MobiFi
    address private mobiFiAddress;

    // floor price of this NFT
    uint256 public price;

    // ???
    mapping(string => uint8) existingURIs;
    
    // List of addresses that have alredy minted an NFT 
    mapping(address => bool) private hasAlreadyMintedNFT;

    // Executed automatically the first time the smart-contruct is deployed 
    constructor(
        address _tokenAddress,
        uint256 _price,
        address _mobiFiAddress
    ) ERC721("PaidHunterAlexTestV4", "PHATV1") {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        tokenAddress = IERC20(_tokenAddress);
        price = _price;
        mobiFiAddress = _mobiFiAddress;
    }

    // ??? 
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
            "https://mobifi-nft-metadata-server-3.herokuapp.com/api/v1/nft-metadata/paid-hunter-alex-v1/";
    }



    // ----------------------------------------------------------------------------------
    // Function: Minting an NFT character
    // Input: 1. Wallet address of the NFT receiver 
    //        2. Random NFT token ID 
    // Output: 1. Which NFT token ID user gets
    // ----------------------------------------------------------------------------------
    function mintNFT(address to, string memory uri)
        public
        payable
        returns (uint256)
    {
        require(existingURIs[uri] != 1, "ERROR_TOKEN_ALREADY_MINTED");

        uint256 supply = count();
        require(supply <= maxSupply, "ALL_NFT_ALREADY_MINTED");

        uint256 tokenId = _tokenIds.current();

        _tokenIds.increment();
        existingURIs[uri] = 1;

        // If you are authorised to mint, then you can mint paid NFT for free, otherwise you need to pay 
        // Currenty this function is not used. 
        // used for specific group of people who have been whitelisted manually by the contract deployer  
        
        if (checkIfAddressHasMinterRole(msg.sender)) {
            _safeMint(to, tokenId);
        } else {
            tokenAddress.transferFrom(msg.sender, address(this), price);
            _safeMint(to, tokenId);
        }

        // It will flag that an NFT has alredy been minted
        _setTokenURI(tokenId, uri);
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

    function addressHasMintedNFT(address userAddress)
        public
        view
        returns (bool)
    {
        return hasAlreadyMintedNFT[userAddress];
    }
    
    // ----------------------------------------------------------------------------------
    // Function: Transfering the MoFis from smart-contract to the MobiFi wallet address 
    // Input: 1. Manually has been insteret durring the contract deployment
    // Output: 1. Transfer
    // ---------------------------------------------------------------------------------- 
    
    function withdraw() public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenAddress.transfer(
            mobiFiAddress,
            tokenAddress.balanceOf(address(this))
        );
    }
}
