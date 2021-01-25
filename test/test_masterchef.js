const assert = require('assert');
const BigNumber = require('bignumber.js')

const Gbt = artifacts.require("./TokenGBT.sol")
const Token = artifacts.require("./Token.sol")
const Members = artifacts.require('./Members.sol')
const MasterChef = artifacts.require('./MasterChef.sol')
const TokenX = artifacts.require('./libraries/TokenX.sol')

contract('MasterChef', ([owner]) => {

    it('Should deploy smart contract', async () => {
        const masterchef = await MasterChef.deployed()
        assert(masterchef.address !== '')
    })

    it('Change owner Token', async () => {
        const token = await Token.deployed()
        await token.transferOwnership(MasterChef.address)
        const ownerNew = await token.owner()
        assert(ownerNew == MasterChef.address)
    })

    it('Change owner Gbt', async () => {
        const gbt = await Gbt.deployed()
        await gbt.transferOwnership(MasterChef.address)
        const ownerNew = await gbt.owner()
        assert(ownerNew == MasterChef.address)
    })

    it('Set referral percentage', async () => {
        const masterchef = await MasterChef.deployed()
        await masterchef.setPercent(new BigNumber((3 * (10 ** 18))), new BigNumber((2 * (10 ** 18))), new BigNumber((1 * (10 ** 18))), new BigNumber((1 * (10 ** 18))), new BigNumber((1 * (10 ** 18))))
        let perc_referral_1 = await masterchef.refPercent(0)
        let perc_referral_2 = await masterchef.refPercent(1)
        let perc_referral_3 = await masterchef.refPercent(2)
        assert(perc_referral_1.toString() == '3000000000000000000' && perc_referral_2.toString() == '2000000000000000000' && perc_referral_3.toString() == '1000000000000000000')
    })

    it('Add Farm', async () => {
        const masterchef = await MasterChef.deployed()
        const tokenX = await TokenX.deployed()
        const poolLength_last = await masterchef.poolLength()
        await masterchef.add(1000, tokenX.address, false)
        const poolLength_new = await masterchef.poolLength()
        assert(poolLength_last.toString() == '1' && poolLength_new.toString() == '2')
    })

    it('Create mod in members', async () => {
        const members = await Members.deployed()
        const masterchef = await MasterChef.deployed()
        await members.addMod(masterchef.address)
        const member_check = await members.mod(masterchef.address)
        assert(member_check)
    })

    it('Send tokensX to 10 addresses', async () => {
        const tokenX = await TokenX.deployed()
        const accounts = await web3.eth.getAccounts()
        if (accounts.length >= 10) {
            for (let i = 1; i <= 10; i++) {
                await tokenX.transfer(accounts[i], new BigNumber((100 * (10 ** 18))))
            }
            const balance_account_1 = await tokenX.balanceOf.call(accounts[1])
            const balance_account_10 = await tokenX.balanceOf.call(accounts[10])
            assert(balance_account_1.toString() == '100000000000000000000' && balance_account_10.toString() == '100000000000000000000')
        } else {
            assert(false)
        }
    })

    it('Approve tokensX to 10-address masterchef', async () => {
        const tokenX = await TokenX.deployed()
        const masterchef = await MasterChef.deployed()
        const accounts = await web3.eth.getAccounts()
        if (accounts.length >= 10) {
            const balance_account_1 = await tokenX.balanceOf.call(accounts[1])
            const balance_account_10 = await tokenX.balanceOf.call(accounts[10])
            if (balance_account_1.toString() == '100000000000000000000' && balance_account_10.toString() == '100000000000000000000') {
                for (let i = 1; i <= 10; i++) {
                    await tokenX.approve(masterchef.address, new BigNumber((100 * (10 ** 18))), { from: accounts[i] })
                }
                assert(true)
            } else {
                assert(false)
            }
        } else {
            assert(false)
        }
    })

    it('Deposit tokensX to 10-address masterchef', async () => {
        const masterchef = await MasterChef.deployed()
        const accounts = await web3.eth.getAccounts()
        if (accounts.length >= 10) {
            const poolInfo_last = await masterchef.poolInfo.call(1)
            const tokens = new BigNumber((100 * (10 ** 18)))
            for (let i = 1; i <= 10; i++) {
                await masterchef.deposit(1, tokens, accounts[0], { from: accounts[i] })
            }
            const poolInfo_new = await masterchef.poolInfo.call(1)
            const pendingToken_user_1 = await masterchef.pendingToken.call(1, accounts[1])
            assert(poolInfo_last.accTokenPerShare.toString() == '0' && poolInfo_new.accTokenPerShare.toString() == '848902701861' && pendingToken_user_1.toString() == '84890270186100000000')
        } else {
            assert(false)
        }
    })

    it('Claim tokens LP in farm', async () => {
        const masterchef = await MasterChef.deployed()
        const token = await Token.deployed()
        const accounts = await web3.eth.getAccounts()
        const pendingToken_user_1_last = await masterchef.pendingToken.call(1, accounts[1])
        const balanceToken_user_1_last = await token.balanceOf.call(accounts[1])
        await masterchef.deposit(1, 0, accounts[0], { from: accounts[1] })
        const pendingToken_user_1_new = await masterchef.pendingToken.call(1, accounts[1])
        const balanceToken_user_1_new = await token.balanceOf.call(accounts[1])
        assert(pendingToken_user_1_last.toString() == '84890270186100000000' && balanceToken_user_1_last.toString() == '0' && pendingToken_user_1_new.toString() == '0' && balanceToken_user_1_new.toString() == '94922302003488000000')
    })

    it('Withdraw tokens LP in farm', async () => {
        const masterchef = await MasterChef.deployed()
        const accounts = await web3.eth.getAccounts()
        const pendingToken_user_1_last = await masterchef.userInfo.call(1, accounts[1])
        await masterchef.withdraw(1, pendingToken_user_1_last.amount, { from: accounts[1] })
        const pendingToken_user_1_new = await masterchef.userInfo.call(1, accounts[1])
        assert(pendingToken_user_1_last.amount.toString() == '100000000000000000000' && pendingToken_user_1_new.amount.toString() == '0')
    })

    it('Staking token', async () => {
        const masterchef = await MasterChef.deployed()
        const token = await Token.deployed()
        const accounts = await web3.eth.getAccounts()
        const balanceToken_user_1_last = await token.balanceOf.call(accounts[1])
        await token.approve(masterchef.address, balanceToken_user_1_last, { from: accounts[1] })
        await masterchef.enterStaking(balanceToken_user_1_last, accounts[0], { from: accounts[1] })
        const balanceToken_user_1_new = await token.balanceOf.call(accounts[1])
        assert(balanceToken_user_1_last.toString() == '98163112205988000000' && balanceToken_user_1_new.toString() == '0')
    })

    it('Creation of temporary blocks', async () => {
        const masterchef = await MasterChef.deployed()
        const token = await Token.deployed()
        const accounts = await web3.eth.getAccounts()
        for (let i = 1; i <= 100; i++) {
            await token.approve(masterchef.address, new BigNumber(100), { from: accounts[1] })
        }
        assert(true)
    })

    it('Claim staking ', async () => {
        const masterchef = await MasterChef.deployed()
        const token = await Token.deployed()
        const accounts = await web3.eth.getAccounts()
        const pendingToken_user_1_last = await masterchef.pendingToken.call(0, accounts[1])
        const balanceToken_user_1_last = await token.balanceOf.call(accounts[1])
        await masterchef.enterStaking(0, accounts[0], { from: accounts[1] })
        const pendingToken_user_1_new = await masterchef.pendingToken.call(0, accounts[1])
        const balanceToken_user_1_new = await token.balanceOf.call(accounts[1])
        assert(pendingToken_user_1_last.toString() == '999249812453111549020' && balanceToken_user_1_last.toString() == '0' && pendingToken_user_1_new.toString() == '0' && balanceToken_user_1_new.toString() == '1089981695423832874434')
    })

    it('Withdraw staking', async () => {
        const masterchef = await MasterChef.deployed()
        const accounts = await web3.eth.getAccounts()
        const pendingToken_user_1_last = await masterchef.userInfo.call(0, accounts[1])
        await masterchef.leaveStaking(pendingToken_user_1_last.amount, { from: accounts[1] })
        const pendingToken_user_1_new = await masterchef.userInfo.call(0, accounts[1])
        assert(pendingToken_user_1_last.amount.toString() == '98163112205988000000' && pendingToken_user_1_new.amount.toString() == '0')
    })

    it('emergencyWithdraw LP', async () => {
        const accounts = await web3.eth.getAccounts()
        const masterchef = await MasterChef.deployed()
        const tokenX = await TokenX.deployed()
        const balanceToken_user_1_last = await tokenX.balanceOf.call(accounts[0])
        await tokenX.approve(masterchef.address, new BigNumber(1), { from: accounts[0] })
        await masterchef.deposit(1, new BigNumber(1), accounts[0], { from: accounts[0] })
        const balanceToken_user_1_new = await tokenX.balanceOf.call(accounts[0])
        await masterchef.emergencyWithdraw(1, { from: accounts[0] })
        const balanceToken_user_1_whit_withdraw = await tokenX.balanceOf.call(accounts[0])
        assert(balanceToken_user_1_last.toString() == '999000000000000000000000' && balanceToken_user_1_new.toString() == '998999999999999999999999' && balanceToken_user_1_whit_withdraw.toString() == '999000000000000000000000')
    })

    it('Change address lottery', async () => {
        const accounts = await web3.eth.getAccounts()
        const masterchef = await MasterChef.deployed()
        await masterchef.lottery(accounts[0])
        const lotteryaddr = await masterchef.lotteryaddr.call()
        assert(lotteryaddr == accounts[0])
    })

    it('Lottery mint tokens', async () => {
        const accounts = await web3.eth.getAccounts()
        const masterchef = await MasterChef.deployed()
        const token = await Token.deployed()
        const balanceToken_user_1_last = await token.balanceOf.call(accounts[7])
        await masterchef.lotteryGain(accounts[7], new BigNumber((100 * (10 ** 18))))
        const balanceToken_user_1_new = await token.balanceOf.call(accounts[7])
        assert(balanceToken_user_1_last.toString() == '0' && balanceToken_user_1_new.toString() == '100000000000000000000')
    })

    it('Change address controller', async () => {
        const accounts = await web3.eth.getAccounts()
        const masterchef = await MasterChef.deployed()
        await masterchef.controller(accounts[0])
        const controlleraddr = await masterchef.controlleraddr.call()
        assert(controlleraddr == accounts[0])
    })

    it('Controller mint tokens', async () => {
        const accounts = await web3.eth.getAccounts()
        const masterchef = await MasterChef.deployed()
        const token = await Token.deployed()
        const balanceToken_user_1_last = await token.balanceOf.call(accounts[8])
        await masterchef.mintController(accounts[8], new BigNumber((100 * (10 ** 18))))
        const balanceToken_user_1_new = await token.balanceOf.call(accounts[8])
        assert(balanceToken_user_1_last.toString() == '0' && balanceToken_user_1_new.toString() == '100000000000000000000')
    })    

})