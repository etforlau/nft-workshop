// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

error CreatorIsNotDao();
error TokenDoesNotExist();
error TokenAlreadyExists();
error NftIsUncraftable();

contract ManuvantaraCollection is ERC1155, Ownable, Pausable {
    struct Token {
        string name;
        string symbol;
        bool isFungible;
        uint256 tokenId;
    }

    uint256 public s_lastTokenId;
    mapping(string => uint256) internal s_symbolToId;
    Token[] public s_collection;
    mapping(address => mapping(uint256 => uint256))
        public s_userToTokensToNumbers;
    bool[] public s_whitelist;

    constructor() ERC1155("") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function existenceCheck(uint256 _id) internal view {
        if (_id >= getLastTokenId()) {
            revert TokenDoesNotExist();
        }
    }

    function nonfungibleCheck(uint256 _id) internal view {
        if (!getCollection()[_id].isFungible) {
            revert NftIsUncraftable();
        }
    }

    function mint(address _to, uint256 _id, uint256 _amount) public onlyOwner {
        existenceCheck(_id);
        nonfungibleCheck(_id);
        s_userToTokensToNumbers[_to][_id] += _amount;
        _mint(_to, _id, _amount, "");
    }

    function mint(uint256 _id, uint256 _amount) internal {
        s_userToTokensToNumbers[msg.sender][_id] += _amount;
        _mint(msg.sender, _id, _amount, "");
    }

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            existenceCheck(_ids[i]);
        }
        for (uint256 i = 0; i < _amounts.length; i++) {
            s_userToTokensToNumbers[_to][_ids[i]] += _amounts[i];
        }
        _mintBatch(_to, _ids, _amounts, "");
    }

    function mintBatch(
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < _amounts.length; i++) {
            s_userToTokensToNumbers[msg.sender][_ids[i]] += _amounts[i];
        }
        _mintBatch(msg.sender, _ids, _amounts, "");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function getLastTokenId() internal view returns (uint256) {
        return s_lastTokenId;
    }

    function increaseLastTokenId() internal {
        s_lastTokenId++;
    }

    function getCollection() internal view returns (Token[] memory) {
        return s_collection;
    }

    function getWhitelist() internal view returns (bool[] memory) {
        return s_whitelist;
    }

    function _getIdBySymbol(
        string calldata _symbol
    ) internal view returns (uint256) {
        Token[] memory collection = getCollection();
        bool wasfound;
        uint foundIndex;
        for (uint256 i = 0; i < collection.length; i++) {
            if (
                keccak256(abi.encodePacked(collection[i].symbol)) ==
                keccak256(abi.encodePacked(_symbol))
            ) {
                foundIndex = i;
                wasfound = true;
                break;
            }
        }
        if (!wasfound) {
            revert TokenDoesNotExist();
        }
        return collection[foundIndex].tokenId;
    }

    function expandCollection(
        string memory _name,
        string memory _symbol,
        bool _isFungible
    ) internal {
        uint256 lastTokenId = getLastTokenId();
        Token[] memory collection = getCollection();
        for (uint256 i = 0; i < collection.length; i++) {
            if (
                keccak256(abi.encodePacked(collection[i].name)) ==
                keccak256(abi.encodePacked(_name)) ||
                keccak256(abi.encodePacked(collection[i].symbol)) ==
                keccak256(abi.encodePacked(_symbol))
            ) {
                revert TokenAlreadyExists();
            }
        }
        if (!_isFungible) {
            mint(lastTokenId, 1);
        }
        s_collection.push(Token(_name, _symbol, _isFungible, lastTokenId));
        s_whitelist.push(true);
        increaseLastTokenId();
    }

    function allow(string calldata symbol) internal {
        uint256 changedId = _getIdBySymbol(symbol);
        existenceCheck(changedId);
        s_whitelist[changedId] = true;
    }

    function forbid(string calldata symbol) internal {
        uint changedId = _getIdBySymbol(symbol);
        existenceCheck(changedId);
        s_whitelist[changedId] = false;
    }

    function getTokensRegister()
        internal
        view
        returns (mapping(address => mapping(uint256 => uint256)) storage)
    {
        return s_userToTokensToNumbers;
    }

    function takeTokensAway(
        uint256[] memory _inputsIds,
        uint256[] memory _inputsAmounts
    ) internal {
        for (uint256 i = 0; i < _inputsIds.length; i++) {
            s_userToTokensToNumbers[msg.sender][
                _inputsIds[i]
            ] -= _inputsAmounts[i];
        }
    }

    function takeTokensAway(uint256 _outputId, uint256 _outputAmount) internal {
        s_userToTokensToNumbers[msg.sender][_outputId] -= _outputAmount;
    }
}
