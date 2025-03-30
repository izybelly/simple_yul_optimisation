// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract LessDumbLotteryContract {
    uint private secretNumber; // storage slot 0
    mapping(address => uint) public guesses; // storage slot 1
    string secretWord;

    function getSecretNumber() external view returns (uint) {
        assembly {
            // Step 1: Load secretNumber at storage slot 0
            let _secretNumber := sload(0)
            // also written as let _secretNumber := sload(secretNumber.slot)

            // Slot 2: Get free memory pointer
            // The address in memory we can write to
            let ptr := mload(0x40)

            // Step 3: Write the value to the address
            // First parameter: Address in memory
            // Second parameter: Value to store
            mstore(ptr, _secretNumber)

            // Step 4: Return the value
            // First parameter: Address where value is stored
            // Second parameter: Suze of parameter returned (32 bytes)
            return(ptr, 0x20)
        }
    }

    function getSecretNumber2() external view returns (uint) {
        assembly {
            // A shorter way
            // Can store the value at `0` as first 2 slots in memory are used as scratch space
            let _secretNumnber := sload(0)
            mstore(0, _secretNumnber)
            return(0, 0x20)
        }
    }

    function setSecretNumber(uint _number) external {
        assembly {
            // Step 1: get the slot number
            let slot := secretNumber.slot

            // Step 2: Use SSTORE to store the new value
            sstore(slot, _number)
        }
    }

    function addGuess(uint _guess) external {
        assembly {
            let ptr := mload(0x40)

            // Step 1: Prepare concatenated key + slot (64 bytes)
            // [0-31]: caller() (padded to 32 bytes)
            mstore(ptr, caller())
            // [32 - 63]: guesses slot (padded to 32 bytes)
            mstore(add(ptr, 0x20), guesses.slot)

            // Step 1 is equivalent to (in memory)
            // abi.encode(caller(), guesses.slot)

            // Step 2: Compute the hash of caller() and guesses.slot
            let slot := keccak256(ptr, 0x40)

            // Step 3: Store the value at that slot
            sstore(slot, _guess)
        }
    }

    // When using memory, the EVM will prepare a memory slot for the variable
    function hashSecretWord1(
        string memory _str
    ) external pure returns (bytes32) {
        assembly {
            // Note _str is just a pointer to the string
            // `_str`: length of the string
            // `_str` + 32: string itself

            let strSize := mload(_str)
            let strAddress := add(_str, 32)

            // Pass address of string and its size
            let hash := keccak256(strAddress, strSize)

            // Cheaper to use slot 0
            mstore(0, hash)

            return(0, 32)
        }
    }

    // Using calldata is cheaper than writing to memory
    function hashSecretWord2(string calldata) external {
        assembly {
            // The calldata represents the entire data passed to a contract when calling a function
            // First 4 bytes refer to the function signature

            // calldataload(4) skips the signature bytes -> loads 32 bytes
            // add 4 to get the offset at byte 36
            let strOffset := add(4, calldataload(4))

            let strSize := calldataload(strOffset)

            let ptr := mload(0x40)

            // Copy the value of the string into the free memory
            calldatacopy(ptr, add(strOffset, 0x20), strSize)

            // compute the hash of the string
            // the string is stored at `ptr`
            let hash := keccak256(ptr, strSize)

            // store it to storage
            sstore(secretWord.slot, hash)
        }
    }

    function addMultipleGuesses(
        address[] memory _users,
        uint[] memory _guesses
    ) external {
        assembly {
            let usersSize := mload(_users)
            let guessesSize := mload(_guesses)

            // Check that both arrays are the same size
            // 0: false, 1: true
            if iszero(eq(usersSize, guessesSize)) {
                revert(0, 0)
            }

            for {
                let i := 0
            } lt(i, usersSize) {
                i := add(i, 1)
            } {
                // add(i, 1): _users is the size of the array, the values start 32 bytes after
                // mul(0x20, ...)): Convert index to byte offset
                // add(_users, ...): Get memory location of element
                // mload(...): Loads 32 bytes
                let userAddress := mload(add(_users, mul(0x20, add(i, 1))))

                let userBalance := mload(add(_guesses, mul(0x20, add(i, 1))))

                // Store the address at 0 memory slot
                mstore(0, userAddress)

                // Store the guesses slot at 0x20 memory slot
                mstore(0x20, guesses.slot)

                // Calculate the storage slot number
                let slot := keccak256(0, 0x40)

                sstore(slot, userBalance)
            }
        }
    }
}
