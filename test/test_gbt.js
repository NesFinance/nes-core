const assert = require('assert');

const TokenGBT = artifacts.require("./TokenGBT.sol")
const Token = artifacts.require("./Token.sol")

contract('TokenGBT', ([owner]) => {

    it('Should deploy smart contract', async () => {
        const gbt = await TokenGBT.deployed()
        assert(gbt.address !== '')
    })

    it('get balance owner token', async () => {
        const gbt = await TokenGBT.deployed()
        const balance = await gbt.balanceOf.call(owner)
        assert('0', balance.toString())
    })

    it('transfer tokens', async () => {
        const accounts = await web3.eth.getAccounts()
        const gbt = await TokenGBT.deployed()
        const balance_last = await gbt.balanceOf.call(owner)
        await gbt.mint(owner, 100)
        await gbt.transfer(accounts[1], 100)
        const balance_new = await gbt.balanceOf.call(accounts[1])
        assert(balance_last.toString() != balance_new.toString() && balance_new.toString() == '100')
    })

    it('transferFrom tokens', async () => {
        const accounts = await web3.eth.getAccounts()
        const gbt = await TokenGBT.deployed()
        await gbt.mint(owner, 100)
        const balance_last = await gbt.balanceOf.call(owner)
        await gbt.approve(accounts[2], 100)
        await gbt.transferFrom(owner, accounts[2], 100, { from: accounts[2] })
        const balance_new = await gbt.balanceOf.call(accounts[2])
        assert(balance_last.toString() == balance_new.toString() && balance_new.toString() == '100')
    })

    it('transfer token main', async () => {
        const accounts = await web3.eth.getAccounts()
        const token = await TokenGBT.deployed()
        const tokenMain = await Token.deployed()
        await tokenMain.mint(token.address, 100)
        const balance_last = await tokenMain.balanceOf.call(token.address)
        await token.safeTokenTransfer(accounts[3], 100);
        const balance_new = await tokenMain.balanceOf.call(accounts[3])
        assert(balance_last.toString() == balance_new.toString() && balance_new.toString() == '100')
    })    

    it('burn tokens', async () => {
        const token = await TokenGBT.deployed()
        await token.mint(owner, 100)
        const balance_last = await token.balanceOf.call(owner)
        await token.burn(owner, 100)
        const balance_new = await token.balanceOf.call(owner)
        assert(balance_last.toString() != balance_new.toString())
    })

    it('has an Ownership', async () => {
        const token = await Token.deployed()
        assert(await token.owner(), owner)
    })

    it('change Ownership', async () => {
        const accounts = await web3.eth.getAccounts()
        const token = await Token.deployed()
        await token.transferOwnership(accounts[2])
        const ownerNew = await token.owner()
        assert(ownerNew == accounts[2])
    })

    it('renounce Ownership', async () => {
        const accounts = await web3.eth.getAccounts()
        const token = await Token.deployed()
        const owner_last = await token.owner()
        await token.renounceOwnership({ from: accounts[2] })
        const owner_new = await token.owner()
        assert(owner_last != owner_new)
    })

})