
const MasterChef = artifacts.require('./MasterChef.sol')
const Controller = artifacts.require('./Controller.sol')

module.exports = async function (deployer) {
    const masterChef = await MasterChef.deployed()
    await deployer.deploy(Controller, masterChef.address)
}