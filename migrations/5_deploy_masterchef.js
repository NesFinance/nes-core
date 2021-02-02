const MasterChef = artifacts.require('./MasterChef.sol')
const TokenGBT = artifacts.require('./TokenGBT.sol')
const Token = artifacts.require('./Token.sol')
const Members = artifacts.require('./Members.sol')

module.exports = async function (deployer) {
    const gbtToken = await TokenGBT.deployed()
    const token = await Token.deployed()
    const members = await Members.deployed()
    let statusChef = true
    if (parseInt(process.env.MASTERCHEF_TEST) == 1) {
        statusChef = false
    }
    await deployer.deploy(
        MasterChef, 
        token.address, // Token address
        gbtToken.address, // GBT address
        members.address, // Members address
        process.env.ROUTER, // Router address
        process.env.FACTORY, // Factory address
        process.env.WBNB, // WBNB address
        process.env.DEV_ADDRESS, // Your address where you get tokens - should be a multisig
        web3.utils.toWei(process.env.TOKENS_PER_BLOCK), // Number of tokens rewarded per block, e.g., 100
        process.env.START_BLOCK // Block number when token mining starts
    )
    if(statusChef){
        const masterChef = await MasterChef.deployed()
        masterChef.initLP()
    }
}