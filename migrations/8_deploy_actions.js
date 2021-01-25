const BigNumber = require('bignumber.js')
const Token = artifacts.require("./Token.sol")
const GBTToken = artifacts.require('./TokenGBT.sol')
const Members = artifacts.require('./Members.sol')
const Lottery = artifacts.require("./Lottery.sol")
const MasterChef = artifacts.require('./MasterChef.sol')


module.exports = async function (deployer) {
    const token = await Token.deployed()
    const gbtToken = await GBTToken.deployed()
    const members = await Members.deployed()
    const lottery = await Lottery.deployed()
    const masterchef = await MasterChef.deployed()

    if (parseInt(process.env.DEPLOY_ACTIONS) == 1) {

        await members.addMod(masterchef.address)
        await members.addSupport(masterchef.address)
        await members.addMod(process.env.DEV_ADDRESS)
        await members.addSupport(process.env.DEV_ADDRESS)
        await members.addMember(process.env.DEV_ADDRESS, process.env.DEV_ADDRESS)

        await lottery.addMod(process.env.DEV_ADDRESS)
        await lottery.addSupport(process.env.DEV_ADDRESS)
        await lottery.setFinishedCount(1000)
        await lottery.setTurns(10)
        await lottery.setTokensGame(new BigNumber((100 * (10 ** 18))))
        await lottery.addressPayment(process.env.DEV_ADDRESS)
        await lottery.setPercent(40, 20, 15, 10, 8, 7)

        await token.mint(process.env.DEV_ADDRESS, web3.utils.toWei(process.env.TOKENS_MINT))
        await token.transferOwnership(masterchef.address)

        await gbtToken.mint(process.env.DEV_ADDRESS, web3.utils.toWei(process.env.TOKENS_MINT))
        await gbtToken.transferOwnership(masterchef.address)

        await masterchef.setPercent(new BigNumber((3 * (10 ** 18))), new BigNumber((2 * (10 ** 18))), new BigNumber((1 * (10 ** 18))), new BigNumber((1 * (10 ** 18))), new BigNumber((1 * (10 ** 18))))
        await masterchef.lottery(lottery.address)

        if (parseInt(process.env.TRANSFER_OWNER_TO_DEV) == 1) {
            await members.transferOwnership(process.env.DEV_ADDRESS)
            await lottery.transferOwnership(process.env.DEV_ADDRESS)
            await masterchef.transferOwnership(process.env.DEV_ADDRESS)
        }

    }


}