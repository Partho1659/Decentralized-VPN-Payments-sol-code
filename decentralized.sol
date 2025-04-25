// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedVPN {
    address public owner;
    bool public isPaused;

    mapping(address => uint256) public providerBalances;
    mapping(address => bool) public registeredProviders;
    mapping(address => uint256) public providerRates; // in wei
    mapping(address => mapping(address => uint256)) public sessionsUsed; // user => provider => count

    event PaymentMade(address indexed user, address indexed provider, uint256 amount);
    event Withdrawal(address indexed provider, uint256 amount);
    event ProviderRegistered(address provider);
    event ProviderDeregistered(address provider);
    event RateUpdated(address provider, uint256 newRate);
    event SessionStarted(address indexed user, address indexed provider);
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

    modifier onlyRegisteredProvider() {
        require(registeredProviders[msg.sender], "Not a registered provider");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // === Provider Functions ===

    function registerProvider() external {
        require(!registeredProviders[msg.sender], "Already registered");
        registeredProviders[msg.sender] = true;
        emit ProviderRegistered(msg.sender);
    }

    function deregisterProvider() external onlyRegisteredProvider {
        registeredProviders[msg.sender] = false;
        emit ProviderDeregistered(msg.sender);
    }

    function setRate(uint256 rateInWei) external onlyRegisteredProvider {
        providerRates[msg.sender] = rateInWei;
        emit RateUpdated(msg.sender, rateInWei);
    }

    function getRate(address provider) external view returns (uint256) {
        return providerRates[provider];
    }

    // === User Functions ===

    function payVPNProvider(address provider) external payable onlyWhenNotPaused {
        require(msg.value > 0, "Payment must be greater than 0");
        require(registeredProviders[provider], "Provider not registered");

        providerBalances[provider] += msg.value;
        emit PaymentMade(msg.sender, provider, msg.value);
    }

    function payForSession(address provider) external payable onlyWhenNotPaused {
        require(registeredProviders[provider], "Provider not registered");
        uint256 rate = providerRates[provider];
        require(rate > 0, "Provider rate not set");
        require(msg.value == rate, "Incorrect payment amount");

        providerBalances[provider] += msg.value;
        sessionsUsed[msg.sender][provider] += 1;

        emit PaymentMade(msg.sender, provider, msg.value);
        emit SessionStarted(msg.sender, provider);
    }

    function getSessionsUsed(address user, address provider) external view returns (uint256) {
        return sessionsUsed[user][provider];
    }

    // === Provider Withdrawal ===

    function withdraw() external {
        uint256 balance = providerBalances[msg.sender];
        require(balance > 0, "No balance to withdraw");
        providerBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
        emit Withdrawal(msg.sender, balance);
    }

    function getProviderBalance(address provider) external view returns (uint256) {
        return providerBalances[provider];
    }

    // === Admin Functions ===

    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getContractBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    function togglePause() external onlyOwner {
        isPaused = !isPaused;
        emit ContractPaused(isPaused);
    }

    // === Fallback Protection ===

    receive() external payable {
        revert("Direct payments not allowed. Use functions.");
    }

    fallback() external payable {
        revert("Function does not exist.");
    }
}
