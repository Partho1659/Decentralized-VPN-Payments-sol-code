// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedVPN {
    address public owner;
    bool public isPaused;

    mapping(address => uint256) public providerBalances;
    mapping(address => bool) public registeredProviders;
    mapping(address => uint256) public providerRates; // wei per session
    mapping(address => mapping(address => uint256)) public sessionsUsed; // user => provider => count
    mapping(address => uint256) public userBalances; // prepaid balance for users
    mapping(address => bool) public providerActiveStatus;

    event PaymentMade(address indexed user, address indexed provider, uint256 amount);
    event Withdrawal(address indexed provider, uint256 amount);
    event ProviderRegistered(address provider);
    event ProviderDeactivated(address provider);
    event RateUpdated(address provider, uint256 newRate);
    event SessionStarted(address indexed user, address indexed provider);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event ContractPaused(bool isPaused);
    event BalanceAdded(address indexed user, uint256 amount);
    event UserRefunded(address indexed user, uint256 amount);

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
        providerActiveStatus[msg.sender] = true;
        emit ProviderRegistered(msg.sender);
    }

    function deactivateProvider() external onlyRegisteredProvider {
        providerActiveStatus[msg.sender] = false;
        emit ProviderDeactivated(msg.sender);
    }

    function setRate(uint256 rateInWei) external onlyRegisteredProvider {
        providerRates[msg.sender] = rateInWei;
        emit RateUpdated(msg.sender, rateInWei);
    }

    function getRate(address provider) external view returns (uint256) {
        return providerRates[provider];
    }

    // === User Functions ===

    function addBalance() external payable onlyWhenNotPaused {
        require(msg.value > 0, "Must send some Ether");
        userBalances[msg.sender] += msg.value;
        emit BalanceAdded(msg.sender, msg.value);
    }

    function payVPNProvider(address provider) external payable onlyWhenNotPaused {
        require(msg.value > 0, "Payment must be greater than 0");
        require(registeredProviders[provider] && providerActiveStatus[provider], "Provider not active");
        providerBalances[provider] += msg.value;
        emit PaymentMade(msg.sender, provider, msg.value);
    }

    function payForSession(address provider) external onlyWhenNotPaused {
        require(registeredProviders[provider] && providerActiveStatus[provider], "Inactive provider");
        uint256 rate = providerRates[provider];
        require(rate > 0, "Rate not set");
        require(userBalances[msg.sender] >= rate, "Insufficient balance");

        userBalances[msg.sender] -= rate;
        providerBalances[provider] += rate;
        sessionsUsed[msg.sender][provider] += 1;

        emit PaymentMade(msg.sender, provider, rate);
        emit SessionStarted(msg.sender, provider);
    }

    function payForMultipleSessions(address provider, uint256 sessions) external onlyWhenNotPaused {
        require(registeredProviders[provider] && providerActiveStatus[provider], "Inactive provider");
        uint256 rate = providerRates[provider];
        uint256 totalCost = rate * sessions;
        require(rate > 0 && sessions > 0, "Invalid rate or session count");
        require(userBalances[msg.sender] >= totalCost, "Insufficient balance");

        userBalances[msg.sender] -= totalCost;
        providerBalances[provider] += totalCost;
        sessionsUsed[msg.sender][provider] += sessions;

        emit PaymentMade(msg.sender, provider, totalCost);
        emit SessionStarted(msg.sender, provider);
    }

    function refundUser(uint256 amount) external onlyWhenNotPaused {
        require(userBalances[msg.sender] >= amount, "Insufficient user balance");
        userBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit UserRefunded(msg.sender, amount);
    }

    function getSessionsUsed(address user, address provider) external view returns (uint256) {
        return sessionsUsed[user][provider];
    }

    function getUserBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }

    // === Provider Withdrawal ===

    function withdraw() external onlyRegisteredProvider {
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
        require(newOwner != address(0), "Zero address");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    function togglePause() external onlyOwner {
        isPaused = !isPaused;
        emit ContractPaused(isPaused);
    }

    // === Fallback Protection ===

    receive() external payable {
        revert("Use addBalance or pay functions");
    }

    fallback() external payable {
        revert("Function does not exist");
    }
}
