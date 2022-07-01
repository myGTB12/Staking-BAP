pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPToken is ERC20{
    constructor() ERC20("LP Token", "LPT") {
        _mint(address(this), 10000000);
        _mint(msg.sender, 1000000);
    } 
}