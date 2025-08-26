// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Tamagotchi is ERC721 {
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

    //Variables
    uint256 private s_tokenCounter;
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
        string memory happyImageUri,
        string memory sadImageUri,
        string memory neutralImageUri,
        string memory hungryImageUri,
        string memory boredImageUri,
        string memory stinkyImageUri,
        string memory lethargicImageUri
    ) ERC721("Tamagotchi", "TMG") {
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
        chooseState(s_tokenCounter);
        s_tokenCounter++;
        emit NftMinted(msg.sender, s_tokenCounter - 1);
    }

    function chooseState(uint256 tokenId) public {
        if (s_tokenIdToHunger[tokenId] <= 30)
            s_tokenIdToPetState[tokenId] = PetState.HUNGRY;
        else if (s_tokenIdToHappiness[tokenId] <= 30)
            s_tokenIdToPetState[tokenId] = PetState.SAD;
        else if (s_tokenIdToEnergy[tokenId] <= 40)
            s_tokenIdToPetState[tokenId] = PetState.LETHARGIC;
        else if (s_tokenIdToFun[tokenId] <= 30)
            s_tokenIdToPetState[tokenId] = PetState.BORED;
        else if (s_tokenIdToHygiene[tokenId] <= 40)
            s_tokenIdToPetState[tokenId] = PetState.STINKY;
        else if (
            s_tokenIdToHappiness[tokenId] > 40 &&
            s_tokenIdToHappiness[tokenId] <= 60
        ) s_tokenIdToPetState[tokenId] = PetState.NEUTRAL;
        else s_tokenIdToPetState[tokenId] = PetState.HAPPY;
    }

    function feed(
        uint256 tokenId
    ) public onlyAuthorizedPersons(tokenId) isValidToken(tokenId) {
        s_tokenIdToHunger[tokenId] = s_tokenIdToHunger[tokenId] + 30 <= 100
            ? s_tokenIdToHunger[tokenId] + 30
            : 100;

        chooseState(tokenId);
        emit Feeding(msg.sender, tokenId, s_tokenIdToHunger[tokenId]);
    }

    function play(
        uint256 tokenId
    ) public onlyAuthorizedPersons(tokenId) isValidToken(tokenId) {
        s_tokenIdToFun[tokenId] = s_tokenIdToFun[tokenId] + 30 <= 100
            ? s_tokenIdToFun[tokenId] + 30
            : 100;
        chooseState(tokenId);
        emit Playing(msg.sender, tokenId, s_tokenIdToFun[tokenId]);
    }

    function bathe(
        uint256 tokenId
    ) public onlyAuthorizedPersons(tokenId) isValidToken(tokenId) {
        s_tokenIdToHygiene[tokenId] = s_tokenIdToHygiene[tokenId] + 30 <= 100
            ? s_tokenIdToHygiene[tokenId] + 30
            : 100;
        chooseState(tokenId);
        emit Bathing(msg.sender, tokenId, s_tokenIdToHygiene[tokenId]);
    }

    function cuddle(
        uint256 tokenId
    ) public onlyAuthorizedPersons(tokenId) isValidToken(tokenId) {
        s_tokenIdToHappiness[tokenId] = s_tokenIdToHappiness[tokenId] + 30 <=
            100
            ? s_tokenIdToHappiness[tokenId] + 30
            : 100;
        chooseState(tokenId);
        emit Cuddling(msg.sender, tokenId, s_tokenIdToHappiness[tokenId]);
    }

    function sleep(
        uint256 tokenId
    ) public onlyAuthorizedPersons(tokenId) isValidToken(tokenId) {
        s_tokenIdToEnergy[tokenId] = s_tokenIdToEnergy[tokenId] + 30 <= 100
            ? s_tokenIdToEnergy[tokenId] + 30
            : 100;
        chooseState(tokenId);
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
