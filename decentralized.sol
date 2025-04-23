// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedVPN {
    address public owner;
    mapping(address => uint256) public providerBalances;

    event PaymentMade(address indexed user, address indexed provider, uint256 amount);
    event Withdrawal(address indexed provider, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    // Function to pay VPN provider
    function payVPNProvider(address provider) external payable {
        require(msg.value > 0, "Payment must be greater than 0");
        providerBalances[provider] += msg.value;
        emit PaymentMade(msg.sender, provider, msg.value);
    }

    // Function for providers to withdraw their earnings
    function withdraw() external {
        uint256 balance = providerBalances[msg.sender];
        require(balance > 0, "No balance to withdraw");
        providerBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
        emit Withdrawal(msg.sender, balance);
    }

    // Emergency: Owner can withdraw funds if needed (optional safety)
    function emergencyWithdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }
}
