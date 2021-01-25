const TokenGBT = artifacts.require('./TokenGBT.sol')
const Token = artifacts.require('./Token.sol')

module.exports = async function (deployer) {
    const token = await Token.deployed()
    await deployer.deploy(TokenGBT, "Lumaris GBT", "LUMG", token.address)
}