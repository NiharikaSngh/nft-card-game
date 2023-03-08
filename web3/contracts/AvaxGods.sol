// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';

/// @title AVAXGods
/// @notice This contract handles the token management and battle logic for the AVAXGods game

contract AVAXGods is ERC1155, Ownable, ERC1155Supply {
  string public baseURI; // baseURI where token metadata is stored
  uint256 public totalSupply; // Total number of tokens minted
  uint256 public constant DEVIL = 0;
  uint256 public constant GRIFFIN = 1;
  uint256 public constant FIREBIRD = 2;
  uint256 public constant KAMO = 3;
  uint256 public constant KUKULKAN = 4;
  uint256 public constant CELESTION = 5;

  uint256 public constant MAX_ATTACK_DEFEND_STRENGTH = 10;

  enum BattleStatus{ PENDING, STARTED, ENDED }

  /// @dev GameToken struct to store player token info
  struct GameToken {
    string name; /// @param name battle card name; set by player
    uint256 id; /// @param id battle card token id; will be randomly generated
    uint256 attackStrength; /// @param attackStrength battle card attack; generated randomly
    uint256 defenseStrength; /// @param defenseStrength battle card defense; generated randomly
  }

  /// @dev Player struct to store player info
  struct Player {
    address playerAddress; /// @param playerAddress player wallet address
    string playerName; /// @param playerName player name; set by player during registration
    uint256 playerMana; /// @param playerMana player mana; affected by battle results
    uint256 playerHealth; /// @param playerHealth player health; affected by battle results
    bool inBattle; /// @param inBattle boolean to indicate if a player is in battle
  }

  /// @dev Battle struct to store battle info
  struct Battle {
    BattleStatus battleStatus; /// @param battleStatus enum to indicate battle status
    bytes32 battleHash; /// @param battleHash a hash of the battle name
    string name; /// @param name battle name; set by player who creates battle
    address[2] players; /// @param players address array representing players in this battle
    uint8[2] moves; /// @param moves uint array representing players' move
    address winner; /// @param winner winner address
  }

  mapping(address => uint256) public playerInfo; // Mapping of player addresses to player index in the players array
  mapping(address => uint256) public playerTokenInfo; // Mapping of player addresses to player token index in the gameTokens array
  mapping(string => uint256) public battleInfo; // Mapping of battle name to battle index in the battles array

  Player[] public players; // Array of players
  GameToken[] public gameTokens; // Array of game tokens
  Battle[] public battles; // Array of battles

  //accepts param of type address
  //it's public that means we can call it from outside
  //it wud return a boolean
  function isPlayer(address addr) public view returns (bool) {
    //if add is zero, player does not exist
    if(playerInfo[addr] == 0) {
      return false;
    } else {
      return true;
    }
  }

  function getPlayer(address addr) public view returns (Player memory) {
    require(isPlayer(addr), "Player doesn't exist!");
    return players[playerInfo[addr]];
  }

  function getAllPlayers() public view returns (Player[] memory) {
    return players;
  }

  function isPlayerToken(address addr) public view returns (bool) {
    if(playerTokenInfo[addr] == 0) {
      return false;
    } else {
      return true;
    }
  }

  //simply returns playr token
  function getPlayerToken(address addr) public view returns (GameToken memory) {
    require(isPlayerToken(addr), "Game token doesn't exist!");
    return gameTokens[playerTokenInfo[addr]];
  }

  function getAllPlayerTokens() public view returns (GameToken[] memory) {
    return gameTokens;
  }

  // Battle getter function
  function isBattle(string memory _name) public view returns (bool) {
    if(battleInfo[_name] == 0) {
      return false;
    } else {
      return true;
    }
  }

  function getBattle(string memory _name) public view returns (Battle memory) {
    require(isBattle(_name), "Battle doesn't exist!");
    return battles[battleInfo[_name]];
  }

  function getAllBattles() public view returns (Battle[] memory) {
    return battles;
  }

  function updateBattle(string memory _name, Battle memory _newBattle) private {
    require(isBattle(_name), "Battle doesn't exist");
    battles[battleInfo[_name]] = _newBattle;
  }

  // Events
  event NewPlayer(address indexed owner, string name);
  event NewBattle(string battleName, address indexed player1, address indexed player2);
  event BattleEnded(string battleName, address indexed winner, address indexed loser);
  event BattleMove(string indexed battleName, bool indexed isFirstMove);
  event NewGameToken(address indexed owner, uint256 id, uint256 attackStrength, uint256 defenseStrength);
  event RoundEnded(address[2] damagedPlayers);

  /// @dev Initializes the contract by setting a `metadataURI` to the token collection
  /// @param _metadataURI baseURI where token metadata is stored
  constructor(string memory _metadataURI) ERC1155(_metadataURI) {
    baseURI = _metadataURI; // Set baseURI
    initialize();
  }

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  function initialize() private {
    gameTokens.push(GameToken("", 0, 0, 0));
    players.push(Player(address(0), "", 0, 0, false));
    battles.push(Battle(BattleStatus.PENDING, bytes32(0), "", [address(0), address(0)], [0, 0], address(0)));
  }

  /// @dev Registers a player
  /// @param _name player name; set by player
  function registerPlayer(string memory _name, string memory _gameTokenName) external {
    //require in solidity performs a check that can throw us out of the func call
    //can check if player registered already by using isPlayer func above
    require(!isPlayer(msg.sender), "Player already registered"); // Require that player is not already registered
    
    //id equals curr num of players
    uint256 _id = players.length;
    //push player to player's array
    //creating an instance of a player 
    //Player is constructor of class player 
    //to check what are the params of this constr search struct Player
    //addre, name, mana=10, health=25, inBattle=false

    players.push(Player(msg.sender, _name, 10, 25, false)); // Adds player to players array
    playerInfo[msg.sender] = _id; // Creates player info mapping

    //automatically create random game token
    createRandomGameToken(_gameTokenName);
    
    //v.imp, emit newplayer event
    //we'll be able to listen to event on the frontend
    //be able to fetch it & do sth based on that event
    emit NewPlayer(msg.sender, _name); // Emits NewPlayer event
  }

  /// @dev internal function to generate random number; used for Battle Card Attack and Defense Strength
  function _createRandomNum(uint256 _max, address _sender) internal view returns (uint256 randomValue) {
    uint256 randomNum = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _sender)));

    randomValue = randomNum % _max;
    if(randomValue == 0) {
      randomValue = _max / 2;
    }

    return randomValue;
  }

  /// @dev internal function to create a new Battle Card
  function _createGameToken(string memory _name) internal returns (GameToken memory) {
    uint256 randAttackStrength = _createRandomNum(MAX_ATTACK_DEFEND_STRENGTH, msg.sender);
    uint256 randDefenseStrength = MAX_ATTACK_DEFEND_STRENGTH - randAttackStrength;
    
    uint8 randId = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100);
    randId = randId % 6;
    if (randId == 0) {
      randId++;
    }
    
    GameToken memory newGameToken = GameToken(
      _name,
      randId,
      randAttackStrength,
      randDefenseStrength
    );

    uint256 _id = gameTokens.length;
    gameTokens.push(newGameToken);
    playerTokenInfo[msg.sender] = _id;

    _mint(msg.sender, randId, 1, '0x0');
    totalSupply++;
    
    emit NewGameToken(msg.sender, randId, randAttackStrength, randDefenseStrength);
    return newGameToken;
  }

  /// @dev Creates a new game token
  /// @param _name game token name; set by player
  function createRandomGameToken(string memory _name) public {
    require(!getPlayer(msg.sender).inBattle, "Player is in a battle"); // Require that player is not already in a battle
    require(isPlayer(msg.sender), "Please Register Player First"); // Require that the player is registered
    
    _createGameToken(_name); // Creates game token
  }

  function getTotalSupply() external view returns (uint256) {
    return totalSupply;
  }

  /// @dev Creates a new battle
  /// @param _name battle name; set by player
  function createBattle(string memory _name) external returns (Battle memory) {
    require(isPlayer(msg.sender), "Please Register Player First"); // Require that the player is registered
    require(!isBattle(_name), "Battle already exists!"); // Require battle with same name should not exist

    //creating special battle hash, google what this func does
    bytes32 battleHash = keccak256(abi.encode(_name));
    
    //initialize new battle
    Battle memory _battle = Battle(
      //pending status when other player hasn't joined the battle
      BattleStatus.PENDING, // Battle pending
      battleHash, // Battle hash
      _name, // Battle name
      //msg.sender is the addr of plyr that created the battle
      [msg.sender, address(0)], // player addresses; player 2 empty until they joins battle
      //at the start both players haven't made the move hence it's zero
      [0, 0], // moves for each player
      address(0) // winner address; empty until battle ends
    );

    uint256 _id = battles.length;
    battleInfo[_name] = _id;
    //push the battle in battles array
    battles.push(_battle);
    
    return _battle;
  }

  /// @dev Player joins battle
  /// @param _name battle name; name of battle player wants to join
  function joinBattle(string memory _name) external returns (Battle memory) {
    Battle memory _battle = getBattle(_name);

    require(_battle.battleStatus == BattleStatus.PENDING, "Battle already started!"); // Require that battle has not started
    require(_battle.players[0] != msg.sender, "Only player two can join a battle"); // Require that player 2 is joining the battle
    require(!getPlayer(msg.sender).inBattle, "Already in battle"); // Require that player is not already in a battle
    
    _battle.battleStatus = BattleStatus.STARTED;
    //set the second player that joined the battle
    _battle.players[1] = msg.sender;
    updateBattle(_name, _battle);

    //update both these players to be true in battle
    players[playerInfo[_battle.players[0]]].inBattle = true;
    players[playerInfo[_battle.players[1]]].inBattle = true;


    emit NewBattle(_battle.name, _battle.players[0], msg.sender); // Emits NewBattle event
    return _battle;
  }

  // Read battle move info for player 1 and player 2
  function getBattleMoves(string memory _battleName) public view returns (uint256 P1Move, uint256 P2Move) {
    Battle memory _battle = getBattle(_battleName);

    P1Move = _battle.moves[0];
    P2Move = _battle.moves[1];

    return (P1Move, P2Move);
  }

  function _registerPlayerMove(uint256 _player, uint8 _choice, string memory _battleName) internal {
    require(_choice == 1 || _choice == 2, "Choice should be either 1 or 2!");
    require(_choice == 1 ? getPlayer(msg.sender).playerMana >= 3 : true, "Mana not sufficient for attacking!");
    battles[battleInfo[_battleName]].moves[_player] = _choice;
  }

  // User chooses attack or defense move for battle card
  //pass choice either to attac or defend & game name

  function attackOrDefendChoice(uint8 _choice, string memory _battleName) external {
    Battle memory _battle = getBattle(_battleName);

    require(
      //battle must have started
        _battle.battleStatus == BattleStatus.STARTED,
        "Battle not started. Please tell another player to join the battle"
    ); // Require that battle has started
    require(
        _battle.battleStatus != BattleStatus.ENDED,
        "Battle has already ended"
    ); // Require that battle has not ended
    require(
      msg.sender == _battle.players[0] || msg.sender == _battle.players[1],
      "You are not in this battle"
    ); // Require that player is in the battle

    //wait till other plyr has made move if u hve already made a mov
    require(_battle.moves[_battle.players[0] == msg.sender ? 0 : 1] == 0, "You have already made a move!");

    _registerPlayerMove(_battle.players[0] == msg.sender ? 0 : 1, _choice, _battleName);

    _battle = getBattle(_battleName);
    uint _movesLeft = 2 - (_battle.moves[0] == 0 ? 0 : 1) - (_battle.moves[1] == 0 ? 0 : 1);
    emit BattleMove(_battleName, _movesLeft == 1 ? true : false);
    
    //if both plyrs hve made their mov
    if(_movesLeft == 0) {
      _awaitBattleResults(_battleName);
    }
  }

  // Awaits battle results
  function _awaitBattleResults(string memory _battleName) internal {
    Battle memory _battle = getBattle(_battleName);

    require(
      msg.sender == _battle.players[0] || msg.sender == _battle.players[1],
      "Only players in this battle can make a move"
    );

    require(
      _battle.moves[0] != 0 &&  _battle.moves[1] != 0,
      "Players still need to make a move"
    );

    //most imp->produces the result of battle
    _resolveBattle(_battle);
  }

  struct P {
    uint index;
    uint move;
    uint health;
    uint attack;
    uint defense;
  }

  /// @dev Resolve battle function to determine winner and loser of battle
  //happens after both plyrs hav made the mov
  /// @param _battle battle; battle to resolve
  function _resolveBattle(Battle memory _battle) internal {

    //first we initialise a plyr 1
    //we get their health, mana, attac, defe val

    P memory p1 = P(
        playerInfo[_battle.players[0]],
        _battle.moves[0],
        getPlayer(_battle.players[0]).playerHealth,
        getPlayerToken(_battle.players[0]).attackStrength,
        getPlayerToken(_battle.players[0]).defenseStrength
    );

    P memory p2 = P(
        playerInfo[_battle.players[1]],
        _battle.moves[1],
        getPlayer(_battle.players[1]).playerHealth,
        getPlayerToken(_battle.players[1]).attackStrength,
        getPlayerToken(_battle.players[1]).defenseStrength
    );

    //create an array of if the plyr has been damaged
    address[2] memory _damagedPlayers = [address(0), address(0)];
    
    //if plyr 1 is attac mov & plyr 2 is also attac mov

    if (p1.move == 1 && p2.move == 1) {
      //end the bttle if attac > health for either

      if (p1.attack >= p2.health) {
        _endBattle(_battle.players[0], _battle);
      } else if (p2.attack >= p1.health) {
        _endBattle(_battle.players[1], _battle);
      } else {

        //decrement plyr health by the amt of attac performed by opposing plyrs

        players[p1.index].playerHealth -= p2.attack;
        players[p2.index].playerHealth -= p1.attack;

        //also decrement plyrs mana bars
        players[p1.index].playerMana -= 3;
        players[p2.index].playerMana -= 3;

        // Both player's health damaged
        _damagedPlayers = _battle.players;
      }
      //if plyr 1 attac & plyr 2 chose to defend

    } else if (p1.move == 1 && p2.move == 2) {

      //this is var taking sum of p2 health + defe

      uint256 PHAD = p2.health + p2.defense;
      //end bttle if attac > phad

      if (p1.attack >= PHAD) {
        _endBattle(_battle.players[0], _battle);
      } else {
        uint256 healthAfterAttack;
        
        //if defe > attac health remains the same

        if(p2.defense > p1.attack) {
          healthAfterAttack = p2.health;
        } else {
          //deduct health+def by attac amt

          healthAfterAttack = PHAD - p1.attack;

          //in this else loop, plyr2 health damaged, push that onto arr
          // Player 2 health damaged
          _damagedPlayers[0] = _battle.players[1];
        }

        players[p2.index].playerHealth = healthAfterAttack;

        players[p1.index].playerMana -= 3;
        players[p2.index].playerMana += 3;
      }
      //same functionality as above jst for diff plyr
    } else if (p1.move == 2 && p2.move == 1) {
      uint256 PHAD = p1.health + p1.defense;
      if (p2.attack >= PHAD) {
        _endBattle(_battle.players[1], _battle);
      } else {
        uint256 healthAfterAttack;
        
        if(p1.defense > p2.attack) {
          healthAfterAttack = p1.health;
        } else {
          healthAfterAttack = PHAD - p2.attack;

          // Player 1 health damaged
          _damagedPlayers[0] = _battle.players[0];
        }

        players[p1.index].playerHealth = healthAfterAttack;

        players[p1.index].playerMana += 3;
        players[p2.index].playerMana -= 3;
      }
      //if both defend only mana Increases
    } else if (p1.move == 2 && p2.move == 2) {
        players[p1.index].playerMana += 3;
        players[p2.index].playerMana += 3;
    }

    //emit this even to frontend
    emit RoundEnded(
      _damagedPlayers
    );

    // Reset moves to 0 
    //so that they can attac again
    _battle.moves[0] = 0;
    _battle.moves[1] = 0;
    updateBattle(_battle.name, _battle);

    // Reset random attack and defense strength
    uint256 _randomAttackStrengthPlayer1 = _createRandomNum(MAX_ATTACK_DEFEND_STRENGTH, _battle.players[0]);
    gameTokens[playerTokenInfo[_battle.players[0]]].attackStrength = _randomAttackStrengthPlayer1;
    gameTokens[playerTokenInfo[_battle.players[0]]].defenseStrength = MAX_ATTACK_DEFEND_STRENGTH - _randomAttackStrengthPlayer1;

    //complex func, read about it
    uint256 _randomAttackStrengthPlayer2 = _createRandomNum(MAX_ATTACK_DEFEND_STRENGTH, _battle.players[1]);
    gameTokens[playerTokenInfo[_battle.players[1]]].attackStrength = _randomAttackStrengthPlayer2;
    gameTokens[playerTokenInfo[_battle.players[1]]].defenseStrength = MAX_ATTACK_DEFEND_STRENGTH - _randomAttackStrengthPlayer2;   
  }

  function quitBattle(string memory _battleName) public {
    Battle memory _battle = getBattle(_battleName);
    require(_battle.players[0] == msg.sender || _battle.players[1] == msg.sender, "You are not in this battle!");

    _battle.players[0] == msg.sender ? _endBattle(_battle.players[1], _battle) : _endBattle(_battle.players[0], _battle);
  }

  /// @dev internal function to end the battle
  /// @param battleEnder winner address
  /// @param _battle battle; taken from attackOrDefend function
  //resets everything
  function _endBattle(address battleEnder, Battle memory _battle) internal returns (Battle memory) {
    require(_battle.battleStatus != BattleStatus.ENDED, "Battle already ended"); // Require that battle has not ended

    _battle.battleStatus = BattleStatus.ENDED;
    _battle.winner = battleEnder;
    updateBattle(_battle.name, _battle);

    uint p1 = playerInfo[_battle.players[0]];
    uint p2 = playerInfo[_battle.players[1]];

    //in bttle to false
    players[p1].inBattle = false;
    players[p1].playerHealth = 25;
    players[p1].playerMana = 10;

    players[p2].inBattle = false;
    players[p2].playerHealth = 25;
    players[p2].playerMana = 10;

    //sets out bttle loser
    address _battleLoser = battleEnder == _battle.players[0] ? _battle.players[1] : _battle.players[0];

    emit BattleEnded(_battle.name, battleEnder, _battleLoser); // Emits BattleEnded event

    return _battle;
  }

  // Turns uint256 into string
  function uintToStr(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return '0';
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  // Token URI getter function
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(baseURI, '/', uintToStr(tokenId), '.json'));
  }

  // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}