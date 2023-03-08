import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { ethers } from 'ethers';
import Web3Modal from 'web3modal';
import { useNavigate } from 'react-router-dom';

import { GetParams } from '../utils/onboard.js';
import { ABI, ADDRESS } from '../contract';
import { createEventListeners } from './createEventListeners';

const GlobalContext = createContext();

export const GlobalContextProvider = ({ children }) => {
  const [walletAddress, setWalletAddress] = useState('');
  const [battleGround, setBattleGround] = useState('bg-astral');
  const [contract, setContract] = useState('');
  const [provider, setProvider] = useState('');
  const [showAlert, setShowAlert] = useState({ status: false, type: 'info', message: '' });
  const [step, setStep] = useState(1);
  const [gameData, setGameData] = useState({ players: [], pendingBattles: [], activeBattle: null });
  const [battleName, setBattleName] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const [updateGameData, setUpdateGameData] = useState(0);

  const navigate = useNavigate();
  const player1Ref = useRef();
  const player2Ref = useRef();

  //* Set battleground to local storage
  //Without this changes done to local storage won't persist on refreshing default bttlegrnd wud appear

  useEffect(() => {
    //get bttlegrnd set frm local str
    const isBattleground = localStorage.getItem('battleground');

    //if bckgrnd is chosen, set it to useState
    if (isBattleground) {
      setBattleGround(isBattleground);
      //else set default bttlegrnd which is useState('bg-astral')
    } else {
      localStorage.setItem('battleground', battleGround);
    }
  }, []);

  //* Reset web3 onboarding modal params
  //listeners for onboardModal
  //only used at start of app when we open app
  useEffect(() => {
    const resetParams = async () => {
      //gets the curr step of the modal
      const currentStep = await GetParams();

      setStep(currentStep.step);
    };

    resetParams();

    //accessing ethereum obj
    //when the acc is changed or wallet is filled with avax the modal disapears
    window?.ethereum?.on('chainChanged', () => resetParams());
    window?.ethereum?.on('accountsChanged', () => resetParams());
  }, []);

  //* Set the wallet address to the state
  const updateCurrentWalletAddress = async () => {
    //https://stackoverflow.com/questions/74326582/metamask-rpc-error-resource-unavailable
    //eth_accounts 
    const accounts = await window?.ethereum?.request({ method: 'eth_accounts' });
    /* console.log(accounts);
    console.log(walletAddress); */
    if (accounts) setWalletAddress(accounts[0]);
  };

  useEffect(() => {
    updateCurrentWalletAddress();

    window?.ethereum?.on('accountsChanged', updateCurrentWalletAddress);
  }, []);

  //* Set the smart contract and provider to the state
  useEffect(() => {
    const setSmartContractAndProvider = async () => {
      const web3Modal = new Web3Modal();
      const connection = await web3Modal.connect();
      const newProvider = new ethers.providers.Web3Provider(connection);
      const signer = newProvider.getSigner();
      const newContract = new ethers.Contract(ADDRESS, ABI, signer);

      setProvider(newProvider);
      setContract(newContract);
    };

    setSmartContractAndProvider();
  }, []);

//* Activate event listeners for the smart contract
  useEffect(() => {
    //if step=-1, we are not ready for game so cannot call func to create event listeners

    if (step!==-1 && contract) {
      createEventListeners({
        //this is an object that passes props
        navigate,
        contract,
        provider,
        walletAddress,
        setShowAlert,
        player1Ref,
        player2Ref,
        setUpdateGameData,
      });
    }
  }, [contract, step]); 

// Set the game data to the state
//use effect changes due to change in updateGameData 
  useEffect(() => {
    const fetchGameData = async () => {
      if (contract) {
        //getAllBattles returns the array of all battle, inside smart cntrct
        const fetchedBattles = await contract.getAllBattles();
        console.log(fetchedBattles);
        //join existing battles
        const pendingBattles = fetchedBattles.filter((battle) => battle.battleStatus === 0);
        let activeBattle = null;

        fetchedBattles.forEach((battle) => {

          if (battle.players.find((player) => player.toLowerCase() === walletAddress.toLowerCase())) {
            //if battle has no winner, it is still an active battle
            if (battle.winner.startsWith('0x00')) {
              activeBattle = battle;
            }
          }
        });

        setGameData({ pendingBattles: pendingBattles.slice(1), activeBattle });
      }
    };

    fetchGameData();
  }, [contract, updateGameData]); 

  //* Handle alerts
  useEffect(() => {
    if (showAlert?.status) {
      const timer = setTimeout(() => {
        setShowAlert({ status: false, type: 'info', message: '' });
      }, [5000]);

      return () => clearTimeout(timer);
    }
  }, [showAlert]);

  //Handle error messages
  useEffect(() => {
    if (errorMessage) {
      const parsedErrorMessage = errorMessage?.reason?.slice('execution reverted: '.length).slice(0, -1);

      if (parsedErrorMessage) {
        setShowAlert({
          status: true,
          type: 'failure',
          message: parsedErrorMessage,
        });
      }
    }
  }, [errorMessage]);

  return (
    <GlobalContext.Provider
      value={{
        contract,
        walletAddress,
        showAlert,
        setShowAlert,
        battleName,
        setBattleName,
        gameData,
        setUpdateGameData,
        setErrorMessage,
        battleGround,
        setBattleGround
      }}
    >
      {children}
    </GlobalContext.Provider>
  );
};

export const useGlobalContext = () => useContext(GlobalContext);
