//these are react hooks
import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

import { useGlobalContext } from '../context';
import { CustomButton, PageHOC } from '../components';
import styles from '../styles';

//newgameData needed to display available battles

const JoinBattle = () => {
    //initialise the navigate
    const navigate = useNavigate();
    //as we r joining we also need to set that battle name
    const { contract, gameData, setShowAlert, setBattleName, setErrorMessage, walletAddress } = useGlobalContext();

    useEffect(() => {
        if (gameData?.activeBattle?.battleStatus === 1) navigate(`/battle/${gameData.activeBattle.name}`);
    }, [gameData]);

    //passed as params from line 44
    const handleClick = async (battleName) => {
        setBattleName(battleName);

        try {
            await contract.joinBattle(battleName);

            setShowAlert({ status: true, type: 'success', message: `Joining ${battleName}` });
        }   catch(error) {
            setErrorMessage(error);
        }
    }
    return (
        <>
            <h2 className={styles.joinHeadText}>Available Battles:</h2>

            <div className={styles.joinContainer}>
                    {/* if gameData pending length exists */}
                {gameData.pendingBattles.length
                    ? gameData.pendingBattles
                        //filter out the battles that curr user has not created
                        //otherwise he would be playing with himself
                        //exclude games created with curr play wallet addr
                        .filter((battle) => !battle.players.includes(walletAddress) && battle.battleStatus !== 1)
                        .map((battle, index) => (
                            <div key={battle.name + index} className={styles.flexBetween}>
                                {/* for each active battle, show it's name & index */}
                                <p className={styles.joinBattleTitle}>{index + 1}. {battle.name}</p>
                                <CustomButton
                                    title="Join"
                                    //to join the desired battle
                                    handleClick={() => handleClick(battle.name)}
                                />
                            </div>
                        )) : (
                            //if pending battles don't exist, reload the page to see 
                        <p className={styles.joinLoading}>Reload the page to see new battles</p>
                    )}
            </div>

            <p className={styles.infoText} onClick={() => navigate('/create-battle')}>
                Or create a new battle
            </p>
        </>
    );
}

export default PageHOC(
    JoinBattle,
    <>Join <br /> a Battle</>,
    <>Join already existing battles</>,
);
