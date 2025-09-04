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
    //structs
    struct PetStats {
        uint256 hunger;
        uint256 happiness;
        uint256 cleanliness;
        uint256 entertainment;
        uint256 energy;
    }

    struct PetTimestamps {
        uint256 fedAt;
        uint256 cuddledAt;
        uint256 bathedAt;
        uint256 playedAt;
        uint256 sleptAt;
        uint256 grewAt;
        uint256 mintedAt;
    }

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
    error Tamagotchi__NotOwner();
    error Tamagotchi__NotValidToken();
    error Tamagotchi__UpkeepNotNeeded();
    error Tamagotchi__PetIsDead();
    error Tamagotchi__RequestNotFound();
    error Tamagotchi__AlreadyFull();
    error Tamagotchi__AlreadyEntertained();
    error Tamagotchi__AlreadyHappy();
    error Tamagotchi__AlreadyClean();
    error Tamagotchi__AlreadyEnergized();

    // Variables
    uint256 private constant DECAY_PRECISION = 1e18;
    uint256 private immutable i_interval;
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
    uint256 private s_lastTimeStamp;
    uint256 private s_tokenCounter;
    uint256 private s_deathAge;

    string private s_happyImageUri;
    string private s_sadImageUri;
    string private s_neutralImageUri;
    string private s_hungryImageUri;
    string private s_boredImageUri;
    string private s_stinkyImageUri;
    string private s_lethargicImageUri;
    string private s_deadImageUri;

    mapping(uint256 => uint) s_tokenIdToPetsAge;
    mapping(uint256 => PetStage) s_tokenIdToPetStage;
    mapping(uint256 => PetState) s_tokenIdToPetState;
    mapping(uint256 => PetStats) s_tokenIdToPetStats;
    mapping(uint256 => PetTimestamps) s_tokenIdToPetTimestamps;

    address private immutable i_owner;

    // Chainlink VRF variables
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
        string memory _lethargicImageUri,
        string memory _deadImageUri
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
        i_owner = msg.sender;
        s_lastTimeStamp = block.timestamp;
        s_tokenCounter = 0;
        s_happyImageUri = _happyImageUri;
        s_sadImageUri = _sadImageUri;
        s_neutralImageUri = _neutralImageUri;
        s_hungryImageUri = _hungryImageUri;
        s_boredImageUri = _boredImageUri;
        s_stinkyImageUri = _stinkyImageUri;
        s_lethargicImageUri = _lethargicImageUri;
        s_deadImageUri = _deadImageUri;
        s_lastProcessedTokenId = 0;
    }

    //Chainlink VRF Request function
    function requestRandomWords() external {
        if (msg.sender != i_owner) revert Tamagotchi__NotOwner();
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
        emit RequestSent(requestId, NUM_WORDS);
    }

    // Mint NFTs (Pets)
    function mintNft() external {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToPetStage[s_tokenCounter] = PetStage.BABY;
        s_tokenIdToPetsAge[s_tokenCounter] = 0;

        uint256 _lastTimestamp = block.timestamp;

        // last timestamp for each state
        s_tokenIdToPetTimestamps[s_tokenCounter].mintedAt = _lastTimestamp;
        s_tokenIdToPetTimestamps[s_tokenCounter].bathedAt = _lastTimestamp;
        s_tokenIdToPetTimestamps[s_tokenCounter].cuddledAt = _lastTimestamp;
        s_tokenIdToPetTimestamps[s_tokenCounter].fedAt = _lastTimestamp;
        s_tokenIdToPetTimestamps[s_tokenCounter].grewAt = _lastTimestamp;
        s_tokenIdToPetTimestamps[s_tokenCounter].playedAt = _lastTimestamp;
        s_tokenIdToPetTimestamps[s_tokenCounter].sleptAt = _lastTimestamp;

        //attributes
        s_tokenIdToPetStats[s_tokenCounter].hunger = 30;
        s_tokenIdToPetStats[s_tokenCounter].happiness = 70;
        s_tokenIdToPetStats[s_tokenCounter].energy = 70;
        s_tokenIdToPetStats[s_tokenCounter].cleanliness = 20;
        s_tokenIdToPetStats[s_tokenCounter].entertainment = 70;
        s_tokenIdToPetState[s_tokenCounter] = PetState.STINKY;

        //events
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
        if (s_tokenIdToPetStats[tokenId].hunger == 100)
            revert Tamagotchi__AlreadyFull();
        s_tokenIdToPetStats[tokenId].hunger = _min(
            s_tokenIdToPetStats[tokenId].hunger + 30,
            100
        );
        s_tokenIdToPetTimestamps[tokenId].fedAt = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Feeding(msg.sender, tokenId, s_tokenIdToPetStats[tokenId].hunger);
    }

    function play(
        uint256 tokenId
    )
        external
        onlyAuthorizedPersons(tokenId)
        isValidToken(tokenId)
        isAlive(tokenId)
    {
        if (s_tokenIdToPetStats[tokenId].entertainment == 100)
            revert Tamagotchi__AlreadyEntertained();
        s_tokenIdToPetStats[tokenId].entertainment = _min(
            s_tokenIdToPetStats[tokenId].entertainment + 30,
            100
        );
        s_tokenIdToPetTimestamps[tokenId].playedAt = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Playing(
            msg.sender,
            tokenId,
            s_tokenIdToPetStats[tokenId].entertainment
        );
    }

    function bathe(
        uint256 tokenId
    )
        external
        onlyAuthorizedPersons(tokenId)
        isValidToken(tokenId)
        isAlive(tokenId)
    {
        if (s_tokenIdToPetStats[tokenId].cleanliness == 100)
            revert Tamagotchi__AlreadyClean();
        s_tokenIdToPetStats[tokenId].cleanliness = _min(
            s_tokenIdToPetStats[tokenId].cleanliness + 30,
            100
        );
        s_tokenIdToPetTimestamps[tokenId].bathedAt = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Bathing(
            msg.sender,
            tokenId,
            s_tokenIdToPetStats[tokenId].cleanliness
        );
    }

    function cuddle(
        uint256 tokenId
    )
        external
        onlyAuthorizedPersons(tokenId)
        isValidToken(tokenId)
        isAlive(tokenId)
    {
        if (s_tokenIdToPetStats[tokenId].happiness == 100)
            revert Tamagotchi__AlreadyHappy();
        s_tokenIdToPetStats[tokenId].happiness = _min(
            s_tokenIdToPetStats[tokenId].happiness + 30,
            100
        );
        s_tokenIdToPetTimestamps[tokenId].cuddledAt = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Cuddling(
            msg.sender,
            tokenId,
            s_tokenIdToPetStats[tokenId].happiness
        );
    }

    function sleep(
        uint256 tokenId
    )
        external
        onlyAuthorizedPersons(tokenId)
        isValidToken(tokenId)
        isAlive(tokenId)
    {
        if (s_tokenIdToPetStats[tokenId].energy == 100)
            revert Tamagotchi__AlreadyEnergized();
        s_tokenIdToPetStats[tokenId].energy = _min(
            s_tokenIdToPetStats[tokenId].energy + 30,
            100
        );
        s_tokenIdToPetTimestamps[tokenId].sleptAt = block.timestamp;
        s_tokenIdToPetState[tokenId] = _chooseState(tokenId);
        emit Sleeping(msg.sender, tokenId, s_tokenIdToPetStats[tokenId].energy);
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
            uint256 _lastTimestamp = block.timestamp;

            // HUNGER
            s_tokenIdToPetStats[i].hunger = _applyDecay(
                i_hungerDecayRatePerSecond,
                s_tokenIdToPetTimestamps[i].fedAt,
                s_tokenIdToPetStats[i].hunger
            );
            s_tokenIdToPetTimestamps[i].fedAt = _lastTimestamp;

            // HAPPINESS
            s_tokenIdToPetTimestamps[i].fedAt = s_tokenIdToPetStats[i]
                .happiness = _applyDecay(
                i_happinessDecayRatePerSecond,
                s_tokenIdToPetTimestamps[i].cuddledAt,
                s_tokenIdToPetStats[i].happiness
            );
            s_tokenIdToPetTimestamps[i].cuddledAt = _lastTimestamp;

            // ENERGY
            s_tokenIdToPetStats[i].energy = _applyDecay(
                i_energyDecayRatePerSecond,
                s_tokenIdToPetTimestamps[i].sleptAt,
                s_tokenIdToPetStats[i].energy
            );
            s_tokenIdToPetTimestamps[i].sleptAt = _lastTimestamp;

            // FUN
            s_tokenIdToPetStats[i].entertainment = _applyDecay(
                i_funDecayRatePerSecond,
                s_tokenIdToPetTimestamps[i].playedAt,
                s_tokenIdToPetStats[i].entertainment
            );
            s_tokenIdToPetTimestamps[i].playedAt = _lastTimestamp;

            // HYGIENE
            s_tokenIdToPetStats[i].cleanliness = _applyDecay(
                i_hygieneDecayRatePerSecond,
                s_tokenIdToPetTimestamps[i].bathedAt,
                s_tokenIdToPetStats[i].cleanliness
            );
            s_tokenIdToPetTimestamps[i].bathedAt = _lastTimestamp;

            s_tokenIdToPetState[i] = _chooseState(i);

            // Handle pet aging and stage progression
            if (
                block.timestamp - s_tokenIdToPetTimestamps[i].grewAt >
                i_growthInterval
            ) {
                s_tokenIdToPetTimestamps[i].grewAt = block.timestamp;
                s_tokenIdToPetsAge[i]++;
                s_tokenIdToPetStage[i] = _chooseStage(
                    s_tokenIdToPetsAge[i],
                    s_deathAge
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
                    s_tokenIdToPetStats[i].hunger,
                    s_tokenIdToPetTimestamps[i].fedAt
                )
            ) continue;
            if (
                _applyDeathStage(
                    i,
                    timestamp,
                    i_sadToleranceInterval,
                    s_tokenIdToPetStats[i].happiness,
                    s_tokenIdToPetTimestamps[i].cuddledAt
                )
            ) continue;
            if (
                _applyDeathStage(
                    i,
                    timestamp,
                    i_boredToleranceInterval,
                    s_tokenIdToPetStats[i].entertainment,
                    s_tokenIdToPetTimestamps[i].playedAt
                )
            ) continue;
            if (
                _applyDeathStage(
                    i,
                    timestamp,
                    i_stinkyToleranceInterval,
                    s_tokenIdToPetStats[i].cleanliness,
                    s_tokenIdToPetTimestamps[i].bathedAt
                )
            ) continue;
            if (
                _applyDeathStage(
                    i,
                    timestamp,
                    i_sleepToleranceInterval,
                    s_tokenIdToPetStats[i].energy,
                    s_tokenIdToPetTimestamps[i].sleptAt
                )
            ) continue;
        }

        s_lastProcessedTokenId += 10;
    }

    // Getter functions

    function getTokenCounter() external view returns (uint256) {
        return s_tokenCounter;
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    function getLastTimestamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getHungerDecayRatePerSecond() external view returns (uint256) {
        return i_hungerDecayRatePerSecond;
    }

    function getHappinessDecayRatePerSecond() external view returns (uint256) {
        return i_happinessDecayRatePerSecond;
    }

    function getEnergyDecayRatePerSecond() external view returns (uint256) {
        return i_energyDecayRatePerSecond;
    }

    function getFunDecayRatePerSecond() external view returns (uint256) {
        return i_funDecayRatePerSecond;
    }

    function getHygieneDecayRatePerSecond() external view returns (uint256) {
        return i_hygieneDecayRatePerSecond;
    }

    function getGrowthInterval() external view returns (uint256) {
        return i_growthInterval;
    }

    function getHungerToleranceInterval() external view returns (uint256) {
        return i_hungerToleranceInterval;
    }

    function getSadToleranceInterval() external view returns (uint256) {
        return i_sadToleranceInterval;
    }

    function getStinkyToleranceInterval() external view returns (uint256) {
        return i_stinkyToleranceInterval;
    }

    function getBoredToleranceInterval() external view returns (uint256) {
        return i_stinkyToleranceInterval;
    }

    function getSeepToleranceInterval() external view returns (uint256) {
        return i_sleepToleranceInterval;
    }

    function getLastProcessedTokenId() external view returns (uint256) {
        return s_lastProcessedTokenId;
    }

    function getHappyImageUri() external view returns (string memory) {
        return s_happyImageUri;
    }

    function getSadImageUri() external view returns (string memory) {
        return s_sadImageUri;
    }

    function getNeutralImageUri() external view returns (string memory) {
        return s_neutralImageUri;
    }

    function getHungryImageUri() external view returns (string memory) {
        return s_hungryImageUri;
    }

    function getBoredImageUri() external view returns (string memory) {
        return s_boredImageUri;
    }

    function getStinkyImageUri() external view returns (string memory) {
        return s_stinkyImageUri;
    }

    function getLethargicImageUri() external view returns (string memory) {
        return s_lethargicImageUri;
    }

    function getTokenIdToPetsAge(
        uint256 tokenId
    ) external view returns (uint256) {
        return s_tokenIdToPetsAge[tokenId];
    }

    function getTokenIdToPetStage(
        uint256 tokenId
    ) external view returns (PetStage) {
        return s_tokenIdToPetStage[tokenId];
    }

    function getTokenIdToPetState(
        uint256 tokenId
    ) external view returns (PetState) {
        return s_tokenIdToPetState[tokenId];
    }

    function getTokenIdToPetStats(
        uint256 tokenId
    ) external view returns (PetStats memory) {
        return s_tokenIdToPetStats[tokenId];
    }

    function getTokenIdToPetTimestamps(
        uint256 tokenId
    ) external view returns (PetTimestamps memory) {
        return s_tokenIdToPetTimestamps[tokenId];
    }

    function deathAge() external view returns (uint256) {
        return s_deathAge;
    }

    function getSubscriptionId() external view returns (uint256) {
        return i_subscriptionId;
    }

    function getKeyHash() external view returns (bytes32) {
        return i_keyHash;
    }

    function getCallbackGasLimit() external view returns (uint32) {
        return i_callbackGasLimit;
    }

    function getVrfCoordinator() external view returns (address) {
        return i_vrfCoordinator;
    }

    function getDecayPrecision() external pure returns (uint256) {
        return DECAY_PRECISION;
    }

    function getRequestConfirmations() external pure returns (uint16) {
        return REQUEST_CONFIRMATIONS;
    }

    function getNumWords() external pure returns (uint16) {
        return NUM_WORDS;
    }

    // Returns the metadata URI for a given tokenId
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory imageURI;
        if (s_tokenIdToPetStage[tokenId] == PetStage.DEAD)
            imageURI = s_deadImageUri;
        else if (s_tokenIdToPetState[tokenId] == PetState.HAPPY)
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
                                Strings.toString(
                                    s_tokenIdToPetStats[tokenId].happiness
                                ),
                                '}, {"trait_type":"hunger","value":',
                                Strings.toString(
                                    s_tokenIdToPetStats[tokenId].hunger
                                ),
                                '}, {"trait_type":"boredom","value":',
                                Strings.toString(
                                    s_tokenIdToPetStats[tokenId].entertainment
                                ),
                                '}, {"trait_type":"hygiene","value":',
                                Strings.toString(
                                    s_tokenIdToPetStats[tokenId].cleanliness
                                ),
                                '}, {"trait_type":"energy","value":',
                                Strings.toString(
                                    s_tokenIdToPetStats[tokenId].energy
                                ),
                                '}, {"trait_type":"age","value":',
                                Strings.toString(s_tokenIdToPetsAge[tokenId]),
                                '}, {"trait_type":"stage","value":"',
                                _petStageToString(s_tokenIdToPetStage[tokenId]),
                                '"}], "image":"',
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
        s_deathAge = (_randomWords[0] % 16) + 5;
        emit PetDeathAgeAssigned(_requestId, s_deathAge);
    }

    //Helper functions (Internal)
    function _applyDecay(
        uint256 decayRatePerSecond,
        uint256 _lastTimestamp,
        uint256 stateLevel
    ) internal view returns (uint256) {
        uint256 decay = (decayRatePerSecond *
            (block.timestamp - _lastTimestamp)) / DECAY_PRECISION;
        return _max(stateLevel - decay, 0);
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
        uint256 hunger = s_tokenIdToPetStats[tokenId].hunger;
        uint256 happiness = s_tokenIdToPetStats[tokenId].happiness;
        uint256 energy = s_tokenIdToPetStats[tokenId].energy;
        uint256 fun = s_tokenIdToPetStats[tokenId].entertainment;
        uint256 hygiene = s_tokenIdToPetStats[tokenId].cleanliness;
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
            minimumLevel = happiness;
            chosenState = PetState.NEUTRAL;
        }

        return chosenState;
    }

    function _chooseStage(
        uint256 age,
        uint256 _deathAge
    ) internal pure returns (PetStage) {
        if (age <= 3) return PetStage.BABY;
        if (age > 3 && age <= _deathAge) return PetStage.ADULT;
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

    function _petStageToString(
        PetStage stage
    ) internal pure returns (string memory) {
        if (stage == PetStage.BABY) return "Baby";
        if (stage == PetStage.ADULT) return "Adult";
        if (stage == PetStage.DEAD) return "Dead";
        return "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "data:application/json;base64,";
    }
}
