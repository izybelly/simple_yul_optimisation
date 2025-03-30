// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract DumbLotteryContract {
    uint private secretNumber;
    mapping(address => uint) public guesses;

    bytes32 public secretWord;

    function getSecretNumber() external view returns (uint) {
        return secretNumber;
    }

    function setSecretNumber(uint _number) external {
        secretNumber = _number;
    }

    function addGuess(uint _guess) external {
        guesses[msg.sender] = _guess;
    }

    function addMultupleGuesses(
        address[] memory _users,
        uint[] memory _guesses
    ) external {
        for (uint i = 0; i < _users.length; i++) {
            guesses[_users[i]] = _guesses[i];
        }
    }

    function hashSecretWord(string memory _str) external returns (bytes32) {
        secretWord = keccak256(abi.encodePacked(_str));
        return secretWord;
    }
}
