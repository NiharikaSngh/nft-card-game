import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';

import styles from '../styles';
import { ActionButton, Alert, Card, GameInfo, PlayerInfo } from '../components';
import { useGlobalContext } from '../context';
import { attack, attackSound, defense, defenseSound, player01 as player01Icon, player02 as player02Icon } from '../assets';
import { playAudio } from '../utils/animation.js';

const Battle = () => {
    const { contract, gameData, battleGround, walletAddress, setErrorMessage, showAlert, setShowAlert, player1Ref, player2Ref } = useGlobalContext();
    //set these to an object  
    const [player2, setPlayer2] = useState({});
    const [player1, setPlayer1] = useState({});     //nagivate to battle/BName
    const { battleName } = useParams();
    const navigate = useNavigate();

    useEffect(() => {
        const getPlayerInfo = async () => {
            try {
                //setting up vars
                let player01Address = null;
                let player02Address = null;
    
                //if the wallet addre is equal to curr play, they are player 1
                //otherwise the other playr is playr 1
                if (gameData.activeBattle.players[0].toLowerCase() === walletAddress.toLowerCase()) {
                    player01Address = gameData.activeBattle.players[0];
                    player02Address = gameData.activeBattle.players[1];
                } else {
                    player01Address = gameData.activeBattle.players[1];
                    player02Address = gameData.activeBattle.players[0];
                }
    
                //based on these vars we can access health bars, mana bars
                const p1TokenData = await contract.getPlayerToken(player01Address);
                const player01 = await contract.getPlayer(player01Address);
                const player02 = await contract.getPlayer(player02Address);
    
                //get attac, defence strength, health & mana
                const p1Att = p1TokenData.attackStrength.toNumber();
                const p1Def = p1TokenData.defenseStrength.toNumber();
                const p1H = player01.playerHealth.toNumber();
                const p1M = player01.playerMana.toNumber();
                const p2H = player02.playerHealth.toNumber();
                const p2M = player02.playerMana.toNumber();
    
                //set usestate
                setPlayer1({ ...player01, att: p1Att, def: p1Def, health: p1H, mana: p1M });
                //'X' is a string as we don't know opposing playr's attac & defense val yet
                //we do know their health & mana as that's shown in the bar
                setPlayer2({ ...player02, att: 'X', def: 'X', health: p2H, mana: p2M });
            } catch (error) {
                setErrorMessage(error.message);
            }
        };
    
        //if there is a contract & active battle then call this func
        if (contract && gameData.activeBattle) getPlayerInfo();
    }, [contract, gameData, battleName]);
    
    //navigate to home if game over, bttle nt active
    useEffect(() => {
        const timer = setTimeout(() => {
            if (!gameData?.activeBattle) navigate('/');
        }, [2000]);         //2 secs
        
        //clear timer
        return () => clearTimeout(timer);
    }, []);
    
    const makeAMove = async (choice) => {
        //if choice is 1, attack if choice 2, defense
        //playaudio is a func
        playAudio(choice === 1 ? attackSound : defenseSound);
    
        try {
            //? gas limit
            //this fun is called from smartCntrt to make the move
            //special param to handle all trans
            await contract.attackOrDefendChoice(choice, battleName, {
                gasLimit: 200000
            });
            
            //alert pops ups 
            setShowAlert({
                status: true,
                type: 'info',
                message: `Initiating ${choice === 1 ? 'attack' : 'defense'}`,
            });
        } catch (error) {
            setErrorMessage(error);
        }
    };

    return (
        <div className={`${styles.flexBetween} ${styles.gameContainer} ${battleGround}`}>
            {/* this is a higher component */}
            {showAlert?.status && <Alert type={showAlert.type} message={showAlert.message} />}

            <PlayerInfo player={player2} playerIcon={player02Icon} mt />

            {/* player2 displayed above */}
            <div className={`${styles.flexCenter} flex-col my-10`}>
                <Card
                    card={player2}
                    title={player2?.playerName}
                    cardRef={player2Ref}
                    playerTwo
                />

                <div className="flex items-center flex-row">
                    <ActionButton
                        //attack the playr
                        imgUrl={attack}
                        handleClick={() => makeAMove(1)}
                        restStyles="mr-2 hover:border-yellow-400"
                    />

                    <Card
                        //now card for playr1
                        card={player1}
                        title={player1?.playerName}
                        cardRef={player1Ref}
                        restStyles="mt-3"
                    />

                    <ActionButton
                        //this is defense action btn
                        imgUrl={defense}
                        handleClick={() => makeAMove(2)}
                        //margin left
                        restStyles="ml-6 hover:border-red-600"
                    />
                </div>
            </div>

            <PlayerInfo player={player1} playerIcon={player01Icon} /> 

            <GameInfo /> 
        </div>
    )
}

export default Battle
