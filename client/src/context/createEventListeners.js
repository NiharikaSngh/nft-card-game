import { ethers } from 'ethers';

import { ABI } from '../contract';
import { playAudio, sparcle } from '../utils/animation.js';
import { defenseSound } from '../assets';

const AddNewEvent = (eventFilter, provider, cb) => {
  //ensures that we don't have multiple event listeners for the same event at the 
  //same time so remove prev liste
  provider.removeListener(eventFilter);

  //below is built-in ethers functionality
  provider.on(eventFilter, (logs) => {
    const parsedLog = (new ethers.utils.Interface(ABI)).parseLog(logs);

    cb(parsedLog);
  });
};

//* Get battle card coordinates
//getBoundingClientRect this func returns the coords
const getCoords = (cardRef) => {
  const { left, top, width, height } = cardRef.current.getBoundingClientRect();

  return {
    //these vals found by trial methd, work best
    pageX: left + width / 2,
    pageY: top + height / 2.25,
  };
}; 

const emptyAccount = '0x0000000000000000000000000000000000000000';

//passing the props
//we get setUpdateGameData from here
export const createEventListeners = ({ navigate, contract, provider, walletAddress, setShowAlert, player1Ref, player2Ref, setUpdateGameData }) => {
  const NewPlayerEventFilter = contract.filters.NewPlayer();
  //({args}) this is the process of destructuring
  AddNewEvent(NewPlayerEventFilter, provider, ({ args }) => {
    console.log('New player created!', args);

    if (walletAddress === args.owner) {
      setShowAlert({
        status: true,
        type: 'success',
        message: 'Player has been successfully registered',
      });
    }
  });

  //goal is to navigate both players to battle area
  const NewBattleEventFilter = contract.filters.NewBattle();
  AddNewEvent(NewBattleEventFilter, provider, ({ args }) => {
    console.log('New battle started!', args, walletAddress);

    //walletAddre is curr play & args is wallet Addre of other playr
    //if it is either playr 1 or playr 2, navigate to battle/bName
    //once we join the bttle, need to update gameData
    if (walletAddress.toLowerCase() === args.player1.toLowerCase() || walletAddress.toLowerCase() === args.player2.toLowerCase()) {
      navigate(`/battle/${args.battleName}`);
    }

    //increment the var
    //based on this we'll know when to reload & show updated info on join battle screen
    setUpdateGameData((prevUpdateGameData) => prevUpdateGameData + 1);
  });

  //right after we create plyr
  const NewGameTokenEventFilter = contract.filters.NewGameToken();
  AddNewEvent(NewGameTokenEventFilter, provider, ({ args }) => {
    console.log('New game token created!', args.owner);

    if (walletAddress.toLowerCase() === args.owner.toLowerCase()) {
      setShowAlert({
        status: true,
        type: 'success',
        message: 'Player game token has been successfully generated',
      });

      //navigate back
      navigate('/create-battle');
    }
  });

  const BattleMoveEventFilter = contract.filters.BattleMove();
  AddNewEvent(BattleMoveEventFilter, provider, ({ args }) => {
    console.log('Battle move initiated!', args);
  });

  const RoundEndedEventFilter = contract.filters.RoundEnded();
  //on line 476
  AddNewEvent(RoundEndedEventFilter, provider, ({ args }) => {
    console.log('Round ended!', args, walletAddress);

    //to check which plyr damaged
    //check with an empty address that means damage arr empty or nt
    //after both moves are attac, explosion along wid sounds occurs
    for (let i = 0; i < args.damagedPlayers.length; i += 1) {
      if (args.damagedPlayers[i] !== emptyAccount) {
        if (args.damagedPlayers[i] === walletAddress) {
          sparcle(getCoords(player1Ref));
        } else if (args.damagedPlayers[i] !== walletAddress) {
          //sparcle func, does animation
          sparcle(getCoords(player2Ref));
        }
      }
      //if nobody got damaged, they defended successfully
      else {
        playAudio(defenseSound);
      }
    }

    setUpdateGameData((prevUpdateGameData) => prevUpdateGameData + 1);
  });

  // Battle Ended event listener
  const BattleEndedEventFilter = contract.filters.BattleEnded();
  AddNewEvent(BattleEndedEventFilter, provider, ({ args }) => {
    //that means we are the winner
    if (walletAddress.toLowerCase() === args.winner.toLowerCase()) {
      setShowAlert({ status: true, type: 'success', message: 'You won!' });
    } else if (walletAddress.toLowerCase() === args.loser.toLowerCase()) {
      setShowAlert({ status: true, type: 'failure', message: 'You lost!' });
    }

    navigate('/create-battle');
  });
}; 