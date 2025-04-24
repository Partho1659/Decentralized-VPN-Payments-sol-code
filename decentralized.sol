// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedVPN {
    address public owner;
    bool public isPaused;

    mapping(address => uint256) public providerBalances;
    mapping(address => bool) public registeredProviders;

    event PaymentMade(address indexed user, address indexed provider, uint256 amount);
    event Withdrawal(address indexed provider, uint256 amount);
    event ProviderRegistered(address provider);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event ContractPaused(bool isPaused);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier onlyWhenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Register as VPN provider
    function registerProvider() external {
        require(!registeredProviders[msg.sender], "Already registered");
        registeredProviders[msg.sender] = true;
        emit ProviderRegistered(msg.sender);
    }

    // Make a payment to a registered provider
    function payVPNProvider(address provider) external payable onlyWhenNotPaused {
        require(msg.value > 0, "Payment must be greater than 0");
        require(registeredProviders[provider], "Provider not registered");
        providerBalances[provider] += msg.value;
        emit PaymentMade(msg.sender, provider, msg.value);
    }

    // Withdraw earnings
    function withdraw() external {
        uint256 balance = providerBalances[msg.sender];
        require(balance > 0, "No balance to withdraw");
        providerBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
        emit Withdrawal(msg.sender, balance);
    }

    // View earnings (redundant, but useful for frontend)
    function getProviderBalance(address provider) external view returns (uint256) {
        return providerBalances[provider];
    }

    // Owner emergency withdraw
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    // Pause or unpause contract
    function togglePause() external onlyOwner {
        isPaused = !isPaused;
        emit ContractPaused(isPaused);
    }
}
