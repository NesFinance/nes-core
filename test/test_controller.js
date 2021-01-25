const assert = require('assert')
const Controller = artifacts.require('./Controller.sol')

contract('Controller', ([owner]) => {

    it('Should deploy smart contract', async () => {
        const controller = await Controller.deployed()
        assert(controller.address !== '')
    })

    it('create mod', async () => {
        const accounts = await web3.eth.getAccounts()
        const controller = await Controller.deployed()
        await controller.addMod(accounts[1])
        const member_check = await controller.mod(accounts[1])
        assert(member_check)
    })

    it('remove mod', async () => {
        const accounts = await web3.eth.getAccounts()
        const controller = await Controller.deployed()
        await controller.removeMod(accounts[1])
        const member_check = await controller.mod(accounts[1])
        assert(member_check === false)
    })

    it('has an Ownership', async () => {
        const controller = await Controller.deployed()
        assert(await controller.owner(), owner)
    })

    it('change Ownership', async () => {
        const accounts = await web3.eth.getAccounts()
        const controller = await Controller.deployed()
        const owner_last = await controller.owner()
        await controller.transferOwnership(accounts[1])
        const owner_new = await controller.owner()
        assert(owner_last != owner_new)
    })

    it('renounce Ownership', async () => {
        const accounts = await web3.eth.getAccounts()
        const controller = await Controller.deployed()
        const owner_last = await controller.owner()
        await controller.renounceOwnership({ from: accounts[1] })
        const owner_new = await controller.owner()
        assert(owner_last != owner_new)
    })

})