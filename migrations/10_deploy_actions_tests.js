const BigNumber = require('bignumber.js')
const Members = artifacts.require('./Members.sol')
const Lottery = artifacts.require("./Lottery.sol")

module.exports = async function (deployer) {
    const lottery = await Lottery.deployed()
    const accounts = await web3.eth.getAccounts()
    const members = await Members.deployed()

    if (parseInt(process.env.DEPLOY_ACTIONS_TEST) == 1) {

        await members.addMember(accounts[1], accounts[0])
        await members.addMember(accounts[2], accounts[0])
        await members.addMember(accounts[3], accounts[0])
        await members.addMember(accounts[4], accounts[0])
    
        await members.addMember(accounts[5], accounts[1])
        await members.addMember(accounts[6], accounts[1])
        await members.addMember(accounts[7], accounts[1])
    
        await members.addMember(accounts[8], accounts[5])
        await members.addMember(accounts[9], accounts[5])
        await members.addMember(accounts[10], accounts[5])
    
        await members.addMember(accounts[11], accounts[7])
        await members.addMember(accounts[12], accounts[7])
    
        await members.addMember(accounts[13], accounts[11])
    
        await lottery.setFinishedCount(100)
        await lottery.setTurns(100)
        await lottery.setTokensGame(new BigNumber((100 * (10 ** 18))))

    }


}