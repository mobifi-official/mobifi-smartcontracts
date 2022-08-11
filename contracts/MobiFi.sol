// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MobiFi is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) public Minter;
    uint256 constant MaxSupply = 150e24;
    using SafeMath for uint256;

    constructor(address _masterAddress, uint256 _preMintAmount)
        ERC20("MobiFi", "MOFI")
    {
        _mint(_masterAddress, _preMintAmount);
    }

    function AddMinter(address _minter) public onlyOwner {
        Minter[_minter] = true;
    }

    function RemoveMinter(address _minter) public onlyOwner {
        Minter[_minter] = false;
    }

    modifier onlyMinter() {
        require(Minter[msg.sender]);
        _;
    }

    function mint(address account, uint256 amount) public onlyMinter {
        uint256 TotalSupply = totalSupply();
        if (TotalSupply.add(amount) > MaxSupply) {
            _mint(account, MaxSupply.sub(TotalSupply));
        } else {
            _mint(account, amount);
        }
    }

    function burn(address account, uint256 amount) public onlyMinter {
        _burn(account, amount);
    }
}
