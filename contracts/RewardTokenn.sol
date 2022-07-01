pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardTokenn is ERC20{
    constructor() ERC20("Test Token", "TEST") {
        _mint(msg.sender, 10000000);
        _mint(address(this), 10000000);
    } 
}