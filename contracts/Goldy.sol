// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    uint256 public feePercentage; // Fee percentage to be deducted on transfers
    address owner;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, 10000 * 10 ** decimals());
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner of this contract");
        _;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 fee = (amount * feePercentage) / 100;
        uint256 amountAfterFee = amount - fee;

        super._transfer(sender, recipient, amountAfterFee);
        if (fee > 0 && msg.sender != owner) {
            super._transfer(sender, address(this), fee);
        }
    }

    function claim() public onlyOwner {
        transferFrom(address(this), owner, balanceOf(address(this)));
    }

    function setFeePercentage(uint256 _feePercentage) external {
        feePercentage = _feePercentage;
    }
}
