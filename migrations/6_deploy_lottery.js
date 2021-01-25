

const MasterChef = artifacts.require('./MasterChef.sol')
const Token = artifacts.require('./Token.sol')
const Lottery = artifacts.require('./Lottery.sol')

module.exports = async function (deployer) {
    const token = await Token.deployed()
    const masterChef = await MasterChef.deployed()
    await deployer.deploy(Lottery, token.address, masterChef.address)
}