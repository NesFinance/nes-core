

const MasterChef = artifacts.require('./MasterChef.sol')
const Token = artifacts.require('./Token.sol')
const Members = artifacts.require('./Members.sol')
const Presale = artifacts.require('./Presale.sol')

module.exports = async function (deployer) {
    const token = await Token.deployed()
    const masterChef = await MasterChef.deployed()
    const members = await Members.deployed()
    await deployer.deploy(Presale, token.address, members.address, masterChef.address)
    const presale = await Presale.deployed()
    await masterChef.presale(presale.address)
}