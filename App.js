// App.js
import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import './App.css'; // optional, if you want to style

const CONTRACT_ADDRESS = "0x061B9ede7731dE3c16767CEA82eF18BED69fD8ce"; // Replace with deployed address
const ABI = [ /* Paste your contract ABI here */ ];

function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [contract, setContract] = useState(null);
  const [account, setAccount] = useState('');
  const [userBalance, setUserBalance] = useState(0);
  const [providerRate, setProviderRate] = useState(0);
  const [contractBalance, setContractBalance] = useState(0);

  useEffect(() => {
    connectWallet();
  }, []);

  async function connectWallet() {
    if (window.ethereum) {
      const tempProvider = new ethers.providers.Web3Provider(window.ethereum);
      const tempSigner = tempProvider.getSigner();
      const tempContract = new ethers.Contract(CONTRACT_ADDRESS, ABI, tempSigner);

      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      setAccount(accounts[0]);
      setProvider(tempProvider);
      setSigner(tempSigner);
      setContract(tempContract);

      console.log("Connected Account:", accounts[0]);
    } else {
      alert("Please install MetaMask");
    }
  }

  async function addBalance(amount) {
    if (!contract) return;
    const tx = await contract.addBalance({ value: ethers.utils.parseEther(amount) });
    await tx.wait();
    alert('Balance added!');
    fetchUserBalance();
  }

  async function fetchUserBalance() {
    if (!contract || !account) return;
    const balance = await contract.getUserBalance(account);
    setUserBalance(ethers.utils.formatEther(balance));
  }

  async function payForSession(providerAddress) {
    if (!contract) return;
    const tx = await contract.payForSession(providerAddress);
    await tx.wait();
    alert('Session paid!');
  }

  async function refundUser(amount) {
    if (!contract) return;
    const tx = await contract.refundUser(ethers.utils.parseEther(amount));
    await tx.wait();
    alert('Refunded!');
    fetchUserBalance();
  }

  async function registerProvider() {
    if (!contract) return;
    const tx = await contract.registerProvider();
    await tx.wait();
    alert('Provider registered!');
  }

  async function withdrawProviderBalance() {
    if (!contract) return;
    const tx = await contract.withdraw();
    await tx.wait();
    alert('Withdraw successful!');
  }

  async function fetchContractBalance() {
    if (!contract) return;
    const balance = await contract.getContractBalance();
    setContractBalance(ethers.utils.formatEther(balance));
  }

  return (
    <div className="App">
      <h1>Decentralized VPN</h1>
      <p>Connected Account: {account}</p>

      <div>
        <button onClick={fetchUserBalance}>Fetch My Balance</button>
        <p>Your Balance: {userBalance} ETH</p>
      </div>

      <div>
        <h3>Add Balance</h3>
        <button onClick={() => addBalance("0.01")}>Add 0.01 ETH</button>
      </div>

      <div>
        <h3>Pay for a VPN Session</h3>
        <input type="text" id="providerAddress" placeholder="Provider Address" />
        <button onClick={() => {
          const providerAddress = document.getElementById('providerAddress').value;
          payForSession(providerAddress);
        }}>Pay for 1 Session</button>
      </div>

      <div>
        <h3>Refund Balance</h3>
        <button onClick={() => refundUser("0.01")}>Refund 0.01 ETH</button>
      </div>

      <div>
        <h3>Provider Options</h3>
        <button onClick={registerProvider}>Register as Provider</button>
        <button onClick={withdrawProviderBalance}>Withdraw Earnings</button>
      </div>

      <div>
        <h3>Admin - Contract Balance</h3>
        <button onClick={fetchContractBalance}>Get Contract Balance</button>
        <p>Contract Balance: {contractBalance} ETH</p>
      </div>
    </div>
  );
}

export default App;
