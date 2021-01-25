#!/usr/bin/env bash

# Deploy contracts
truffle migrate --reset --network bsc_testnet

# Verify Contracts on Etherscan
truffle run verify Members --network bsc_testnet --license SPDX-License-Identifier
truffle run verify Token --network bsc_testnet --license SPDX-License-Identifier
truffle run verify TokenGBT --network bsc_testnet --license SPDX-License-Identifier
truffle run verify MasterChef --network bsc_testnet --license SPDX-License-Identifier
truffle run verify TokenX --network bsc_testnet --license SPDX-License-Identifier
truffle run verify Lottery --network bsc_testnet --license SPDX-License-Identifier
truffle run verify Controller --network bsc_testnet --license SPDX-License-Identifier

# Flats Contracts
mkdir -p flats
rm -rf flats/*
./node_modules/.bin/truffle-flattener contracts/Members.sol > flats/Members.sol
./node_modules/.bin/truffle-flattener contracts/Token.sol > flats/Token.sol
./node_modules/.bin/truffle-flattener contracts/TokenGBT.sol > flats/TokenGBT.sol
./node_modules/.bin/truffle-flattener contracts/MasterChef.sol > flats/MasterChef.sol
./node_modules/.bin/truffle-flattener contracts/TokenX.sol > flats/TokenX.sol
./node_modules/.bin/truffle-flattener contracts/Lottery.sol > flats/Lottery.sol
./node_modules/.bin/truffle-flattener contracts/Controller.sol > flats/Controller.sol
