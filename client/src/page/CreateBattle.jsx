import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

import styles from '../styles';
import { useGlobalContext } from '../context';
import { CustomButton, CustomInput, GameLoad, PageHOC } from '../components';

const CreateBattle = () => {
  const { contract, gameData, battleName, setBattleName, setErrorMessage } = useGlobalContext();
  const [waitBattle, setWaitBattle] = useState(false);
  const navigate = useNavigate();

  //To know if curr player has created a battle or not
  //It is going to change when the gameData changes
  //gameData accessed thru context
  useEffect(() => {
    //if playr has already a game created redirect to that link
    //hence user cannot create new game unless it uses exit game btn
    if (gameData?.activeBattle?.battleStatus === 1) {
      navigate(`/battle/${gameData.activeBattle.name}`);
    } else if (gameData?.activeBattle?.battleStatus === 0) {
      setWaitBattle(true);
    }
  }, [gameData]);

  //make this func asynchronous because contract interactions take time
  const handleClick = async () => {
    if (!battleName === '' || !battleName.trim() === '') return null;

    try {
      //check in smart contr createBattle
      await contract.createBattle(battleName, {
        gasLimit: 200000
      });

      setWaitBattle(true);    //a battle isn't instantaneous because you first have to wait for another player to join you
    } catch (error) {
      setErrorMessage(error);
    }
  };

  return (
    //<> is an empty react fragement
    <>
      {/* If wait battle is true then show the GameLoad component */}
      {waitBattle && <GameLoad />}
      {/* mb is margin bottom */}
      <div className="flex flex-col mb-5">
        <CustomInput
          label="Battle"
          placeHolder="Enter battle name"
          value={battleName}
          handleValueChange={setBattleName}
        />

        <CustomButton
          title="Create Battle"
          handleClick={handleClick}
          restStyles="mt-6"
        />
      </div>
      <p className={styles.infoText} onClick={() => navigate('/join-battle')}>
        Or join already existing battles
      </p>
    </>
  );
};


export default PageHOC(
  CreateBattle,
  <>Create <br /> a new Battle</>,
  <>Create your own battle and wait for other players to join you</>,
);
