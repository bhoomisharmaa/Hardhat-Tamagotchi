// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract Tamagotchi is ERC721, AutomationCompatibleInterface {
    // enums
    enum PetStage {
        BABY,
        ADULT,
        DEAD
    }
    enum PetState {
        HAPPY,
        SAD,
        NEUTRAL,
        HUNGRY,
        BORED,
        STINKY,
        LETHARGIC
    }

    //events
    event NftMinted(address owner, uint256 tokenId);
    event Feeding(address sender, uint256 tokenId, uint256 hungerLevel);
    event Playing(address sender, uint256 tokenId, uint256 funLevel);
    event Bathing(address sender, uint256 tokenId, uint256 hygieneLevel);
    event Cuddling(address sender, uint256 tokenId, uint256 happinessLevel);
    event Sleeping(address sender, uint256 tokenId, uint256 energyLevel);

    //errors
    error Tamagotchi__NotAuthorized();
    error Tamagotchi__NotValidToken();
    error Tamagotchi__UpkeepNotNeeded();

    //Variables
    uint256 private s_tokenCounter;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_hungerDecayInterval;
    uint256 private immutable i_happinessDecayInterval;
    uint256 private immutable i_energyDecayInterval;
    uint256 private immutable i_funDecayInterval;
    uint256 private immutable i_hygieneDecayInterval;

    string private s_happyImageUri;
    string private s_sadImageUri;
    string private s_neutralImageUri;
    string private s_hungryImageUri;
    string private s_boredImageUri;
    string private s_stinkyImageUri;
    string private s_lethargicImageUri;

    mapping(uint256 => uint) s_tokenIdToPetsAge;
    mapping(uint256 => PetStage) s_tokenIdToPetStage;
    mapping(uint256 => PetState) s_tokenIdToPetState;
    mapping(uint256 => uint256) s_tokenIdToHappiness;
    mapping(uint256 => uint256) s_tokenIdToHunger;
    mapping(uint256 => uint256) s_tokenIdToFun;
    mapping(uint256 => uint256) s_tokenIdToHygiene;
    mapping(uint256 => uint256) s_tokenIdToEnergy;
    mapping(uint256 => uint256) s_tokenIdToMintTimestamp;
    mapping(uint256 => uint256) s_tokenIdToLastTimestamp;
    mapping(uint256 => uint256) s_tokenIdToHungerLastTimestamp;
    mapping(uint256 => uint256) s_tokenIdToHappinessLastTimestamp;
    mapping(uint256 => uint256) s_tokenIdToFunLastTimestamp;
    mapping(uint256 => uint256) s_tokenIdToEnergyLastTimestamp;
    mapping(uint256 => uint256) s_tokenIdToHygieneLastTimestamp;

    //modifiers
    modifier onlyAuthorizedPersons(uint256 tokenId) {
        address owner = _ownerOf(tokenId);
        if (!_isAuthorized(owner, msg.sender, tokenId))
            revert Tamagotchi__NotAuthorized();
        _;
    }

    modifier isValidToken(uint256 tokenId) {
        if (tokenId >= s_tokenCounter) revert Tamagotchi__NotValidToken();
        _;
    }

    constructor(
        uint256 interval,
        uint256 hungerDecayInterval,
        uint256 happinessDecayInterval,
        uint256 energyDecayInterval,
        uint256 funDecayInterval,
        uint256 hygieneDecayInterval,
        string memory happyImageUri,
        string memory sadImageUri,
        string memory neutralImageUri,
        string memory hungryImageUri,
        string memory boredImageUri,
        string memory stinkyImageUri,
        string memory lethargicImageUri
    ) ERC721("Tamagotchi", "TMG") {
        i_interval = interval;
        i_hungerDecayInterval = hungerDecayInterval;
        i_happinessDecayInterval = happinessDecayInterval;
        i_energyDecayInterval = energyDecayInterval;
        i_funDecayInterval = funDecayInterval;
        i_hygieneDecayInterval = hygieneDecayInterval;
        s_lastTimeStamp = block.timestamp;
        s_tokenCounter = 0;
        s_happyImageUri = happyImageUri;
        s_sadImageUri = sadImageUri;
        s_neutralImageUri = neutralImageUri;
        s_hungryImageUri = hungryImageUri;
        s_boredImageUri = boredImageUri;
        s_stinkyImageUri = stinkyImageUri;
        s_lethargicImageUri = lethargicImageUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToPetStage[s_tokenCounter] = PetStage.BABY;
        s_tokenIdToPetsAge[s_tokenCounter] = 0;

        uint256 lastTimestamp = block.timestamp;

        // last timestamp for each state
        s_tokenIdToMintTimestamp[s_tokenCounter] = lastTimestamp;
        s_tokenIdToLastTimestamp[s_tokenCounter] = lastTimestamp;
        s_tokenIdToHungerLastTimestamp[s_tokenCounter] = lastTimestamp;
        s_tokenIdToHappinessLastTimestamp[s_tokenCounter] = lastTimestamp;
        s_tokenIdToEnergyLastTimestamp[s_tokenCounter] = lastTimestamp;
        s_tokenIdToFunLastTimestamp[s_tokenCounter] = lastTimestamp;
        s_tokenIdToHygieneLastTimestamp[s_tokenCounter] = lastTimestamp;

        //attributes
        s_tokenIdToHunger[s_tokenCounter] = 30;
        s_tokenIdToHappiness[s_tokenCounter] = 70;
        s_tokenIdToEnergy[s_tokenCounter] = 70;
        s_tokenIdToHygiene[s_tokenCounter] = 20;
        s_tokenIdToFun[s_tokenCounter] = 70;

        s_tokenIdToPetState[s_tokenCounter] = PetState.STINKY;

        s_tokenCounter++;
        emit NftMinted(msg.sender, s_tokenCounter - 1);
    }

    function checkUpkeep(
        bytes calldata
    ) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp - s_lastTimeStamp) > i_interval;
    }

    function performUpkeep(bytes calldata) external override {
        if (block.timestamp - s_lastTimeStamp <= i_interval)
            revert Tamagotchi__UpkeepNotNeeded();

        s_lastTimeStamp = block.timestamp;

        for (uint256 i = 0; i < s_tokenCounter; i++) {
            // HUNGER
            _applyDecay(
                i,
                i_hungerDecayInterval,
                s_tokenIdToHungerLastTimestamp,
                s_tokenIdToHunger
            );

            // HAPPINESS
            _applyDecay(
                i,
                i_happinessDecayInterval,
                s_tokenIdToHappinessLastTimestamp,
                s_tokenIdToHappiness
            );

            // ENERGY
            _applyDecay(
                i,
                i_energyDecayInterval,
                s_tokenIdToEnergyLastTimestamp,
                s_tokenIdToEnergy
            );

            // FUN
            _applyDecay(
                i,
                i_funDecayInterval,
                s_tokenIdToFunLastTimestamp,
                s_tokenIdToFun
            );

            // HYGIENE
            _applyDecay(
                i,
                i_hygieneDecayInterval,
                s_tokenIdToHygieneLastTimestamp,
                s_tokenIdToHygiene
            );

            s_tokenIdToPetState[i] = _chooseState(i);
        }
    }

    function _applyDecay(
        uint256 tokenId,
        uint256 interval,
        mapping(uint256 => uint256) storage lastTimestamp,
        mapping(uint256 => uint256) storage stateLevel
    ) internal {
        uint256 lastStamp = lastTimestamp[tokenId];
        if ((block.timestamp - lastStamp) > interval) {
            uint256 decay = (30 * (block.timestamp - lastStamp)) / interval;
            stateLevel[tokenId] = _max(stateLevel[tokenId] - decay, 0);
            lastTimestamp[tokenId] = block.timestamp;
        }
    }

    function _chooseState(uint256 tokenId) internal view returns (PetState) {
        uint256 hunger = s_tokenIdToHunger[tokenId];
        uint256 happiness = s_tokenIdToHappiness[tokenId];
        uint256 energy = s_tokenIdToEnergy[tokenId];
        uint256 fun = s_tokenIdToFun[tokenId];
        uint256 hygiene = s_tokenIdToHygiene[tokenId];
        uint256 minimumLevel = 100;

        PetState chosenState = PetState.HAPPY;

        if (hunger <= 30 && hunger < minimumLevel) {
            minimumLevel = hunger;
            chosenState = PetState.HUNGRY;
        }
        if (happiness <= 30 && happiness < minimumLevel) {
            minimumLevel = happiness;
            chosenState = PetState.SAD;
        }
        if (energy <= 40 && energy < minimumLevel) {
            minimumLevel = energy;
            chosenState = PetState.LETHARGIC;
        }
        if (fun <= 30 && fun < minimumLevel) {
            minimumLevel = fun;
            chosenState = PetState.BORED;
        }
        if (hygiene <= 40 && hygiene < minimumLevel) {
            minimumLevel = hygiene;
            chosenState = PetState.STINKY;
        }
        if (happiness > 40 && happiness <= 60 && happiness < minimumLevel) {
            minimumLevel = s_tokenIdToHappiness[tokenId];
            chosenState = PetState.NEUTRAL;
        }

        return chosenState;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) return a;
        else return b;
    }

    function feed(
        uint256 tokenId
    ) public onlyAuthorizedPersons(tokenId) isValidToken(tokenId) {
        s_tokenIdToHunger[tokenId] = s_tokenIdToHunger[tokenId] + 30 <= 100
            ? s_tokenIdToHunger[tokenId] + 30
            : 100;
        s_tokenIdToHungerLastTimestamp[tokenId] = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Feeding(msg.sender, tokenId, s_tokenIdToHunger[tokenId]);
    }

    function play(
        uint256 tokenId
    ) public onlyAuthorizedPersons(tokenId) isValidToken(tokenId) {
        s_tokenIdToFun[tokenId] = s_tokenIdToFun[tokenId] + 30 <= 100
            ? s_tokenIdToFun[tokenId] + 30
            : 100;
        s_tokenIdToFunLastTimestamp[tokenId] = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Playing(msg.sender, tokenId, s_tokenIdToFun[tokenId]);
    }

    function bathe(
        uint256 tokenId
    ) public onlyAuthorizedPersons(tokenId) isValidToken(tokenId) {
        s_tokenIdToHygiene[tokenId] = s_tokenIdToHygiene[tokenId] + 30 <= 100
            ? s_tokenIdToHygiene[tokenId] + 30
            : 100;
        s_tokenIdToHygieneLastTimestamp[tokenId] = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Bathing(msg.sender, tokenId, s_tokenIdToHygiene[tokenId]);
    }

    function cuddle(
        uint256 tokenId
    ) public onlyAuthorizedPersons(tokenId) isValidToken(tokenId) {
        s_tokenIdToHappiness[tokenId] = s_tokenIdToHappiness[tokenId] + 30 <=
            100
            ? s_tokenIdToHappiness[tokenId] + 30
            : 100;
        s_tokenIdToHappinessLastTimestamp[tokenId] = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Cuddling(msg.sender, tokenId, s_tokenIdToHappiness[tokenId]);
    }

    function sleep(
        uint256 tokenId
    ) public onlyAuthorizedPersons(tokenId) isValidToken(tokenId) {
        s_tokenIdToEnergy[tokenId] = s_tokenIdToEnergy[tokenId] + 30 <= 100
            ? s_tokenIdToEnergy[tokenId] + 30
            : 100;
        s_tokenIdToEnergyLastTimestamp[tokenId] = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Sleeping(msg.sender, tokenId, s_tokenIdToEnergy[tokenId]);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory imageURI;
        if (s_tokenIdToPetState[tokenId] == PetState.HAPPY)
            imageURI = s_happyImageUri;
        else if (s_tokenIdToPetState[tokenId] == PetState.SAD)
            imageURI = s_sadImageUri;
        else if (s_tokenIdToPetState[tokenId] == PetState.NEUTRAL)
            imageURI = s_neutralImageUri;
        else if (s_tokenIdToPetState[tokenId] == PetState.HUNGRY)
            imageURI = s_hungryImageUri;
        else if (s_tokenIdToPetState[tokenId] == PetState.BORED)
            imageURI = s_boredImageUri;
        else if (s_tokenIdToPetState[tokenId] == PetState.STINKY)
            imageURI = s_stinkyImageUri;
        else if (s_tokenIdToPetState[tokenId] == PetState.LETHARGIC)
            imageURI = s_lethargicImageUri;
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Tamagotchi #',
                                Strings.toString(tokenId),
                                '", "description":"A cute on-chain Tamagotchi pet.", ',
                                '"attributes":[',
                                '{"trait_type":"happiness","value":',
                                Strings.toString(s_tokenIdToHappiness[tokenId]),
                                '}, {"trait_type":"hunger","value":',
                                Strings.toString(s_tokenIdToHunger[tokenId]),
                                '}, {"trait_type":"boredom","value":',
                                Strings.toString(s_tokenIdToFun[tokenId]),
                                '}, {"trait_type":"hygiene","value":',
                                Strings.toString(s_tokenIdToHygiene[tokenId]),
                                '}, {"trait_type":"energy","value":',
                                Strings.toString(s_tokenIdToEnergy[tokenId]),
                                '}], "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
