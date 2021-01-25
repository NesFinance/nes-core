const Token = artifacts.require('./Token.sol')

module.exports = async function (deployer) {
    await deployer.deploy(Token, "Lumaris", "LUM")
}