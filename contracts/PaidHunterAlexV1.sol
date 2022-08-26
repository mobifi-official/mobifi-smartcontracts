// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PaidHunterAlexTestV1 is ERC721, ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Total suplay of NFT
    uint256 public constant maxSupply = 1000;

    // ERC20 Token address
    IERC20 private tokenAddress;

    // MobiFi wallet address to receive nft
    address private mobiFiAddress;

    // floor price of this NFT
    uint256 public price;

    mapping(string => uint8) existingURIs;

    mapping(address => bool) private hasAlreadyMintedNFT;

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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://mobifi-nft-metadata-server-3.herokuapp.com/api/v1/nft-metadata/paid-hunter-alex-v1/";
    }

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

        if (checkIfAddressHasMinterRole(msg.sender)) {
            _safeMint(to, tokenId);
        } else {
            tokenAddress.transferFrom(msg.sender, address(this), price);
            _safeMint(to, tokenId);
        }

        _setTokenURI(tokenId, uri);
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

    function withdraw() public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenAddress.transfer(
            mobiFiAddress,
            tokenAddress.balanceOf(address(this))
        );
    }
}
