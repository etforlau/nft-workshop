// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ManuvantaraCollection.sol";
import "hardhat/console.sol";

error NotEnoughTokens();
error NotAllTokensAreInWhitelist();
error IdsAndNumbersDiffer();
error SomeTokenIsDoubbled();
error RecipeDoesNotExist();

contract Workshop is ManuvantaraCollection {
    struct Recipe {
        uint256 recipeId;
        uint256[] inputsIds;
        uint256[] inputsAmounts;
        uint256 outputId;
    }

    uint256 internal s_lastRecipeId;
    Recipe[] public s_recipies;

    constructor() ManuvantaraCollection() {}

    function Allowed_Exists_Check(
        uint256 _separateId,
        uint256[] memory _array
    ) internal view {
        super.existenceCheck(_separateId);
        for (uint256 i = 0; i < _array.length; i++) {
            super.existenceCheck(_array[i]);
        }
        bool[] memory whitelist = super.getWhitelist();
        if (!whitelist[_separateId]) {
            revert NotAllTokensAreInWhitelist();
        }

        for (uint256 i = 0; i < _array.length; i++) {
            if (!whitelist[_array[i]]) {
                revert NotAllTokensAreInWhitelist();
            }
        }
    }

    function getIdBySymbol(
        string calldata _symbol
    ) public view returns (uint256) {
        return super._getIdBySymbol(_symbol);
    }

    function getLastRecipeId() internal view returns (uint256) {
        return s_lastRecipeId;
    }

    function getRecipies() internal view returns (Recipe[] storage) {
        return s_recipies;
    }

    function createNewToken(
        string memory _name,
        string memory _symbol,
        bool _isFungible
    ) public {
        super.expandCollection(_name, _symbol, _isFungible);
    }

    function addToWhitelist(string calldata symbol) public {
        super.allow(symbol);
    }

    function excludeFromWhitelist(string calldata symbol) public {
        super.forbid(symbol);
    }

    function increaseLastRecipeId() internal {
        s_lastRecipeId++;
    }

    function addRecipe(
        uint256[] memory inputsIds,
        uint256[] memory inputsNum,
        uint256 outputId
    ) public {
        Allowed_Exists_Check(outputId, inputsIds);
        if (inputsNum.length != inputsIds.length) {
            revert IdsAndNumbersDiffer();
        }
        s_recipies.push(
            Recipe(getLastRecipeId(), inputsIds, inputsNum, outputId)
        );
        increaseLastRecipeId();
    }

    function changeRecipe(
        uint256 _recipeId,
        uint256[] memory _inputsIds,
        uint256[] memory _newAmounts
    ) public {
        Allowed_Exists_Check(_inputsIds[0], _inputsIds);
        if (_recipeId >= getLastRecipeId()) {
            revert RecipeDoesNotExist();
        }
        Recipe memory editedRecipe = getRecipies()[_recipeId];
        for (uint256 i = 0; i < _inputsIds.length; i++) {
            for (uint256 j = 0; j < editedRecipe.inputsIds.length; j++) {
                if (editedRecipe.inputsIds[j] == _inputsIds[i]) {
                    editedRecipe.inputsAmounts[j] = _newAmounts[i];
                }
            }
        }
        s_recipies[_recipeId] = editedRecipe;
    }

    function findRecipies(
        string calldata _outputSymbol
    ) public view returns (Recipe[] memory) {
        uint256 neededId = getIdBySymbol(_outputSymbol);
        Recipe[] memory recipies = getRecipies();
        uint256 n = recipies.length;
        for (uint256 i = 0; i < n; i++) {
            if (recipies[i].outputId != neededId) {
                delete recipies[i];
            }
        }
        return recipies;
    }

    function compareArrays(
        uint256[] memory array1,
        uint256[] memory array2
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < array1.length; i++) {
            bool isFound = false;
            for (uint256 j = 0; j < array2.length; j++) {
                if (array2[j] == array1[i]) {
                    isFound = true;
                }
            }
            if (!isFound) {
                return false;
            }
        }
        return true;
    }

    function assembling(
        uint256 _recipeId,
        uint256 _outputAmount
    ) external payable {
        Recipe memory recipe = getRecipies()[_recipeId];
        uint256 outputId = recipe.outputId;
        super.nonfungibleCheck(outputId);
        Allowed_Exists_Check(recipe.outputId, recipe.inputsIds);
        mapping(address => mapping(uint256 => uint256))
            storage userToTokensToNumbers = super.getTokensRegister();
        for (uint256 i = 0; i < recipe.inputsIds.length; i++) {
            if (
                recipe.inputsAmounts[i] * _outputAmount >
                userToTokensToNumbers[msg.sender][recipe.inputsIds[i]]
            ) {
                revert NotEnoughTokens();
            }
        }
        super.takeTokensAway(recipe.inputsIds, recipe.inputsAmounts);
        super.mint(recipe.outputId, _outputAmount);
    }

    function disassembling(
        uint256 _recipeId,
        uint256 _outputAmount
    ) public payable {
        Recipe memory recipe = getRecipies()[_recipeId];
        Allowed_Exists_Check(recipe.outputId, recipe.inputsIds);
        mapping(address => mapping(uint256 => uint256))
            storage userToTokensToNumbers = super.getTokensRegister();
        if (
            _outputAmount < userToTokensToNumbers[msg.sender][recipe.outputId]
        ) {
            revert NotEnoughTokens();
        }

        uint256[] memory calcInputsAmounts = recipe.inputsAmounts;
        for (uint256 i = 0; i < recipe.inputsAmounts.length; i++) {
            calcInputsAmounts[i] *= _outputAmount;
        }
        super.takeTokensAway(recipe.outputId, _outputAmount);
        super.mintBatch(recipe.inputsIds, calcInputsAmounts);
    }
}
