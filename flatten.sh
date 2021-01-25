#!/usr/bin/env bash

mkdir -p flats
rm -rf flats/*
./node_modules/.bin/truffle-flattener contracts/Members.sol > flats/Members.sol
./node_modules/.bin/truffle-flattener contracts/Token.sol > flats/Token.sol
./node_modules/.bin/truffle-flattener contracts/TokenGBT.sol > flats/TokenGBT.sol
./node_modules/.bin/truffle-flattener contracts/MasterChef.sol > flats/MasterChef.sol
./node_modules/.bin/truffle-flattener contracts/TokenX.sol > flats/TokenX.sol
./node_modules/.bin/truffle-flattener contracts/Lottery.sol > flats/Lottery.sol
