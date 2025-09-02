// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Tamagotchi is
    ERC721,
    AutomationCompatibleInterface,
    VRFConsumerBaseV2Plus
{
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

    // events
    event NftMinted(address owner, uint256 tokenId);
    event Feeding(address sender, uint256 tokenId, uint256 hungerLevel);
    event Playing(address sender, uint256 tokenId, uint256 funLevel);
    event Bathing(address sender, uint256 tokenId, uint256 hygieneLevel);
    event Cuddling(address sender, uint256 tokenId, uint256 happinessLevel);
    event Sleeping(address sender, uint256 tokenId, uint256 energyLevel);
    event PetDied(uint256 tokenId, uint256 timestamp);
    event RequestSent(uint256 requestId, uint32 numWords);
    event PetDeathAgeAssigned(uint256 requestId, uint256 deathAge);

    // errors
    error Tamagotchi__NotAuthorized();
    error Tamagotchi__NotValidToken();
    error Tamagotchi__UpkeepNotNeeded();
    error Tamagotchi__PetIsDead();
    error Tamagotchi__RequestNotFound();

    // Variables
    uint256 private s_tokenCounter;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_hungerDecayRatePerSecond;
    uint256 private immutable i_happinessDecayRatePerSecond;
    uint256 private immutable i_energyDecayRatePerSecond;
    uint256 private immutable i_funDecayRatePerSecond;
    uint256 private immutable i_hygieneDecayRatePerSecond;
    uint256 private immutable i_growthInterval;
    uint256 private immutable i_hungerToleranceInterval;
    uint256 private immutable i_sadToleranceInterval;
    uint256 private immutable i_stinkyToleranceInterval;
    uint256 private immutable i_boredToleranceInterval;
    uint256 private immutable i_sleepToleranceInterval;
    uint256 private s_lastProcessedTokenId;
    uint256 private constant DECAY_PRECISION = 1e18;

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
    mapping(uint256 => uint256) s_tokenIdToGrowthLastTimestamp;
    mapping(uint256 => uint256) s_tokenIdToHungerLastTimestamp;
    mapping(uint256 => uint256) s_tokenIdToHappinessLastTimestamp;
    mapping(uint256 => uint256) s_tokenIdToFunLastTimestamp;
    mapping(uint256 => uint256) s_tokenIdToEnergyLastTimestamp;
    mapping(uint256 => uint256) s_tokenIdToHygieneLastTimestamp;
    mapping(uint256 => uint256) s_tokenIdToDeathAge;

    // Chainlink VRF variables
    mapping(uint256 => uint256) s_requestIdToTokenId;
    mapping(uint256 => bool) s_requestIdExists;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint16 private constant NUM_WORDS = 1;
    address private immutable i_vrfCoordinator;

    // modifiers
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

    modifier isAlive(uint256 tokenId) {
        if (s_tokenIdToPetStage[tokenId] == PetStage.DEAD)
            revert Tamagotchi__PetIsDead();
        _;
    }

    // Constructor
    constructor(
        uint256 _interval,
        uint256 _hungerDecayRatePerSecond,
        uint256 _happinessDecayRatePerSecond,
        uint256 _energyDecayRatePerSecond,
        uint256 _funDecayRatePerSecond,
        uint256 _hygieneDecayRatePerSecond,
        uint256 _growthInterval,
        uint256 _hungerToleranceInterval,
        uint256 _sadToleranceInterval,
        uint256 _stinkyToleranceInterval,
        uint256 _boredToleranceInterval,
        uint256 _sleepToleranceInterval,
        uint256 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        string memory _happyImageUri,
        string memory _sadImageUri,
        string memory _neutralImageUri,
        string memory _hungryImageUri,
        string memory _boredImageUri,
        string memory _stinkyImageUri,
        string memory _lethargicImageUri
    ) ERC721("Tamagotchi", "TMG") VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_interval = _interval;
        i_hungerDecayRatePerSecond = _hungerDecayRatePerSecond;
        i_happinessDecayRatePerSecond = _happinessDecayRatePerSecond;
        i_energyDecayRatePerSecond = _energyDecayRatePerSecond;
        i_funDecayRatePerSecond = _funDecayRatePerSecond;
        i_hygieneDecayRatePerSecond = _hygieneDecayRatePerSecond;
        i_growthInterval = _growthInterval;
        i_hungerToleranceInterval = _hungerToleranceInterval;
        i_sadToleranceInterval = _sadToleranceInterval;
        i_stinkyToleranceInterval = _stinkyToleranceInterval;
        i_boredToleranceInterval = _boredToleranceInterval;
        i_sleepToleranceInterval = _sleepToleranceInterval;
        i_subscriptionId = _subscriptionId;
        i_vrfCoordinator = _vrfCoordinator;
        i_keyHash = _keyHash;
        i_callbackGasLimit = _callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_tokenCounter = 0;
        s_happyImageUri = _happyImageUri;
        s_sadImageUri = _sadImageUri;
        s_neutralImageUri = _neutralImageUri;
        s_hungryImageUri = _hungryImageUri;
        s_boredImageUri = _boredImageUri;
        s_stinkyImageUri = _stinkyImageUri;
        s_lethargicImageUri = _lethargicImageUri;
        s_lastProcessedTokenId = 0;
    }

    // Mint NFTs (Pets)
    function mintNft() external {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToPetStage[s_tokenCounter] = PetStage.BABY;
        s_tokenIdToPetsAge[s_tokenCounter] = 0;

        uint256 _lastTimestamp = block.timestamp;

        // last timestamp for each state
        s_tokenIdToMintTimestamp[s_tokenCounter] = _lastTimestamp;
        s_tokenIdToGrowthLastTimestamp[s_tokenCounter] = _lastTimestamp;
        s_tokenIdToHungerLastTimestamp[s_tokenCounter] = _lastTimestamp;
        s_tokenIdToHappinessLastTimestamp[s_tokenCounter] = _lastTimestamp;
        s_tokenIdToEnergyLastTimestamp[s_tokenCounter] = _lastTimestamp;
        s_tokenIdToFunLastTimestamp[s_tokenCounter] = _lastTimestamp;
        s_tokenIdToHygieneLastTimestamp[s_tokenCounter] = _lastTimestamp;

        //attributes
        s_tokenIdToHunger[s_tokenCounter] = 30;
        s_tokenIdToHappiness[s_tokenCounter] = 70;
        s_tokenIdToEnergy[s_tokenCounter] = 70;
        s_tokenIdToHygiene[s_tokenCounter] = 20;
        s_tokenIdToFun[s_tokenCounter] = 70;
        s_tokenIdToPetState[s_tokenCounter] = PetState.STINKY;

        //Chainlink VRF
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        s_requestIdExists[requestId] = true;
        s_requestIdToTokenId[requestId] = s_tokenCounter;

        //events
        emit RequestSent(requestId, NUM_WORDS);
        emit NftMinted(msg.sender, s_tokenCounter);

        s_tokenCounter++;
    }

    // Interaction functions
    function feed(
        uint256 tokenId
    )
        external
        onlyAuthorizedPersons(tokenId)
        isValidToken(tokenId)
        isAlive(tokenId)
    {
        s_tokenIdToHunger[tokenId] = _min(s_tokenIdToHunger[tokenId] + 30, 100);
        s_tokenIdToHungerLastTimestamp[tokenId] = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Feeding(msg.sender, tokenId, s_tokenIdToHunger[tokenId]);
    }

    function play(
        uint256 tokenId
    )
        external
        onlyAuthorizedPersons(tokenId)
        isValidToken(tokenId)
        isAlive(tokenId)
    {
        s_tokenIdToFun[tokenId] = _min(s_tokenIdToFun[tokenId] + 30, 100);
        s_tokenIdToFunLastTimestamp[tokenId] = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Playing(msg.sender, tokenId, s_tokenIdToFun[tokenId]);
    }

    function bathe(
        uint256 tokenId
    )
        external
        onlyAuthorizedPersons(tokenId)
        isValidToken(tokenId)
        isAlive(tokenId)
    {
        s_tokenIdToHygiene[tokenId] = _min(
            s_tokenIdToHygiene[tokenId] + 30,
            100
        );
        s_tokenIdToHygieneLastTimestamp[tokenId] = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Bathing(msg.sender, tokenId, s_tokenIdToHygiene[tokenId]);
    }

    function cuddle(
        uint256 tokenId
    )
        external
        onlyAuthorizedPersons(tokenId)
        isValidToken(tokenId)
        isAlive(tokenId)
    {
        s_tokenIdToHappiness[tokenId] = _min(
            s_tokenIdToHappiness[tokenId] + 30,
            100
        );
        s_tokenIdToHappinessLastTimestamp[tokenId] = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Cuddling(msg.sender, tokenId, s_tokenIdToHappiness[tokenId]);
    }

    function sleep(
        uint256 tokenId
    )
        external
        onlyAuthorizedPersons(tokenId)
        isValidToken(tokenId)
        isAlive(tokenId)
    {
        s_tokenIdToEnergy[tokenId] = _min(s_tokenIdToEnergy[tokenId] + 30, 100);
        s_tokenIdToEnergyLastTimestamp[tokenId] = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Sleeping(msg.sender, tokenId, s_tokenIdToEnergy[tokenId]);
    }

    // Chainlik Automation
    function checkUpkeep(
        bytes calldata
    ) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp - s_lastTimeStamp) > i_interval;
    }

    function performUpkeep(bytes calldata) external override {
        if (block.timestamp - s_lastTimeStamp <= i_interval)
            revert Tamagotchi__UpkeepNotNeeded();

        s_lastTimeStamp = block.timestamp;
        if (s_lastProcessedTokenId >= s_tokenCounter)
            s_lastProcessedTokenId = 0;
        for (
            uint256 i = s_lastProcessedTokenId;
            i < _min(s_tokenCounter, s_lastProcessedTokenId + 10);
            i++
        ) {
            if (s_tokenIdToPetStage[i] == PetStage.DEAD) continue;
            // HUNGER
            _applyDecay(
                i,
                i_hungerDecayRatePerSecond,
                s_tokenIdToHungerLastTimestamp,
                s_tokenIdToHunger
            );

            // HAPPINESS
            _applyDecay(
                i,
                i_happinessDecayRatePerSecond,
                s_tokenIdToHappinessLastTimestamp,
                s_tokenIdToHappiness
            );

            // ENERGY
            _applyDecay(
                i,
                i_energyDecayRatePerSecond,
                s_tokenIdToEnergyLastTimestamp,
                s_tokenIdToEnergy
            );

            // FUN
            _applyDecay(
                i,
                i_funDecayRatePerSecond,
                s_tokenIdToFunLastTimestamp,
                s_tokenIdToFun
            );

            // HYGIENE
            _applyDecay(
                i,
                i_hygieneDecayRatePerSecond,
                s_tokenIdToHygieneLastTimestamp,
                s_tokenIdToHygiene
            );

            s_tokenIdToPetState[i] = _chooseState(i);

            // Handle pet aging and stage progression
            if (
                block.timestamp - s_tokenIdToGrowthLastTimestamp[i] >
                i_growthInterval
            ) {
                s_tokenIdToGrowthLastTimestamp[i] = block.timestamp;
                s_tokenIdToPetsAge[i]++;
                s_tokenIdToPetStage[i] = _chooseStage(
                    s_tokenIdToPetsAge[i],
                    s_tokenIdToDeathAge[i]
                );
                if (s_tokenIdToPetStage[i] == PetStage.DEAD) {
                    emit PetDied(i, block.timestamp);
                    continue;
                }
            }

            // Handle death due to ignorance
            uint256 timestamp = block.timestamp;
            if (
                _applyDeathStage(
                    i,
                    timestamp,
                    i_hungerToleranceInterval,
                    s_tokenIdToHunger[i],
                    s_tokenIdToHungerLastTimestamp[i]
                )
            ) continue;
            if (
                _applyDeathStage(
                    i,
                    timestamp,
                    i_sadToleranceInterval,
                    s_tokenIdToHappiness[i],
                    s_tokenIdToHappinessLastTimestamp[i]
                )
            ) continue;
            if (
                _applyDeathStage(
                    i,
                    timestamp,
                    i_boredToleranceInterval,
                    s_tokenIdToFun[i],
                    s_tokenIdToFunLastTimestamp[i]
                )
            ) continue;
            if (
                _applyDeathStage(
                    i,
                    timestamp,
                    i_stinkyToleranceInterval,
                    s_tokenIdToHygiene[i],
                    s_tokenIdToHygieneLastTimestamp[i]
                )
            ) continue;
            if (
                _applyDeathStage(
                    i,
                    timestamp,
                    i_sleepToleranceInterval,
                    s_tokenIdToEnergy[i],
                    s_tokenIdToEnergyLastTimestamp[i]
                )
            ) continue;
        }

        s_lastProcessedTokenId += 10;
    }

    // Getter functions

    function tokenCounter() external view returns (uint256) {
        return s_tokenCounter;
    }

    function interval() external view returns (uint256) {
        return i_interval;
    }

    function lastTimestamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function hungerDecayRatePerSecond() external view returns (uint256) {
        return i_hungerDecayRatePerSecond;
    }

    function happinessDecayRatePerSecond() external view returns (uint256) {
        return i_happinessDecayRatePerSecond;
    }

    function energyDecayRatePerSecond() external view returns (uint256) {
        return i_energyDecayRatePerSecond;
    }

    function funDecayRatePerSecond() external view returns (uint256) {
        return i_funDecayRatePerSecond;
    }

    function hygieneDecayRatePerSecond() external view returns (uint256) {
        return i_hygieneDecayRatePerSecond;
    }

    function growthInterval() external view returns (uint256) {
        return i_growthInterval;
    }

    function hungerToleranceInterval() external view returns (uint256) {
        return i_hungerToleranceInterval;
    }

    function sadToleranceInterval() external view returns (uint256) {
        return i_sadToleranceInterval;
    }

    function stinkyToleranceInterval() external view returns (uint256) {
        return i_stinkyToleranceInterval;
    }

    function boredToleranceInterval() external view returns (uint256) {
        return i_stinkyToleranceInterval;
    }

    function sleepToleranceInterval() external view returns (uint256) {
        return i_sleepToleranceInterval;
    }

    function lastProcessedTokenId() external view returns (uint256) {
        return s_lastProcessedTokenId;
    }

    function happyImageUri() external view returns (string memory) {
        return s_happyImageUri;
    }

    function sadImageUri() external view returns (string memory) {
        return s_sadImageUri;
    }

    function neutralImageUri() external view returns (string memory) {
        return s_neutralImageUri;
    }

    function hungryImageUri() external view returns (string memory) {
        return s_hungryImageUri;
    }

    function boredImageUri() external view returns (string memory) {
        return s_boredImageUri;
    }

    function stinkyImageUri() external view returns (string memory) {
        return s_stinkyImageUri;
    }

    function lethargicImageUri() external view returns (string memory) {
        return s_lethargicImageUri;
    }

    function tokenIdToPetsAge(uint256 tokenId) external view returns (uint256) {
        return s_tokenIdToPetsAge[tokenId];
    }

    function tokenIdToPetStage(
        uint256 tokenId
    ) external view returns (PetStage) {
        return s_tokenIdToPetStage[tokenId];
    }

    function tokenIdToPetState(
        uint256 tokenId
    ) external view returns (PetState) {
        return s_tokenIdToPetState[tokenId];
    }

    function tokenIdToHappiness(
        uint256 tokenId
    ) external view returns (uint256) {
        return s_tokenIdToHappiness[tokenId];
    }

    function tokenIdToHunger(uint256 tokenId) external view returns (uint256) {
        return s_tokenIdToHunger[tokenId];
    }

    function tokenIdToFun(uint256 tokenId) external view returns (uint256) {
        return s_tokenIdToFun[tokenId];
    }

    function tokenIdToHygiene(uint256 tokenId) external view returns (uint256) {
        return s_tokenIdToHygiene[tokenId];
    }

    function tokenIdToEnergy(uint256 tokenId) external view returns (uint256) {
        return s_tokenIdToEnergy[tokenId];
    }

    function tokenIdToMintTimestamp(
        uint256 tokenId
    ) external view returns (uint256) {
        return s_tokenIdToMintTimestamp[tokenId];
    }

    function tokenIdToGrowthLastTimestamp(
        uint256 tokenId
    ) external view returns (uint256) {
        return s_tokenIdToGrowthLastTimestamp[tokenId];
    }

    function tokenIdToHungerLastTimestamp(
        uint256 tokenId
    ) external view returns (uint256) {
        return s_tokenIdToHungerLastTimestamp[tokenId];
    }

    function tokenIdToHappinessLastTimestamp(
        uint256 tokenId
    ) external view returns (uint256) {
        return s_tokenIdToHappinessLastTimestamp[tokenId];
    }

    function tokenIdToFunLastTimestamp(
        uint256 tokenId
    ) external view returns (uint256) {
        return s_tokenIdToFunLastTimestamp[tokenId];
    }

    function tokenIdToEnergyLastTimestamp(
        uint256 tokenId
    ) external view returns (uint256) {
        return s_tokenIdToEnergyLastTimestamp[tokenId];
    }

    function tokenIdToHygieneLastTimestamp(
        uint256 tokenId
    ) external view returns (uint256) {
        return s_tokenIdToHygieneLastTimestamp[tokenId];
    }

    function tokenIdToDeathAge(
        uint256 tokenId
    ) external view returns (uint256) {
        return s_tokenIdToDeathAge[tokenId];
    }

    function subscriptionId() external view returns (uint256) {
        return i_subscriptionId;
    }

    function keyHash() external view returns (bytes32) {
        return i_keyHash;
    }

    function callbackGasLimit() external view returns (uint32) {
        return i_callbackGasLimit;
    }

    function vrfCoordinator() external view returns (address) {
        return i_vrfCoordinator;
    }

    function decayPrecision() external pure returns (uint256) {
        return DECAY_PRECISION;
    }

    function RequestConfirmations() external pure returns (uint16) {
        return REQUEST_CONFIRMATIONS;
    }

    function numWords() external pure returns (uint16) {
        return NUM_WORDS;
    }

    // Returns the metadata URI for a given tokenId
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

    // Chainlink VRF
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        if (!s_requestIdExists[_requestId])
            revert Tamagotchi__RequestNotFound();
        uint256 tokenId = s_requestIdToTokenId[_requestId];
        uint256 deathAge = (_randomWords[0] % 16) + 5;
        s_tokenIdToDeathAge[tokenId] = deathAge;
        emit PetDeathAgeAssigned(_requestId, deathAge);
    }

    //Helper functions (Internal)
    function _applyDecay(
        uint256 tokenId,
        uint256 decayRatePerSecond,
        mapping(uint256 => uint256) storage _lastTimestamp,
        mapping(uint256 => uint256) storage stateLevel
    ) internal {
        uint256 lastStamp = _lastTimestamp[tokenId];
        uint256 decay = (decayRatePerSecond * (block.timestamp - lastStamp)) /
            DECAY_PRECISION;
        stateLevel[tokenId] = _max(stateLevel[tokenId] - decay, 0);
        _lastTimestamp[tokenId] = block.timestamp;
    }

    function _applyDeathStage(
        uint256 tokenId,
        uint256 timestamp,
        uint256 toleranceInterval,
        uint256 stateLevel,
        uint256 _lastTimestamp
    ) internal returns (bool) {
        if (stateLevel == 0 && timestamp - _lastTimestamp > toleranceInterval) {
            s_tokenIdToPetStage[tokenId] = PetStage.DEAD;
            emit PetDied(tokenId, timestamp);
            return true;
        } else return false;
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

    function _chooseStage(
        uint256 age,
        uint256 deathAge
    ) internal pure returns (PetStage) {
        if (age <= 3) return PetStage.BABY;
        if (age > 3 && age <= deathAge) return PetStage.ADULT;
        return PetStage.DEAD;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) return a;
        else return b;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) return a;
        else return b;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "data:application/json;base64,";
    }
}
