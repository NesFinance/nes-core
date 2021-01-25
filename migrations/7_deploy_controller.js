
const MasterChef = artifacts.require('./MasterChef.sol')
const Controller = artifacts.require('./Controller.sol')
const Members = artifacts.require('./Members.sol')

module.exports = async function (deployer) {
    const masterChef = await MasterChef.deployed()
    const members = await Members.deployed()
    await deployer.deploy(Controller, masterChef.address, members.address)
}