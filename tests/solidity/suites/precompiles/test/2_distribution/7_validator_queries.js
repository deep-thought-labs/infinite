const { expect } = require('chai');
const hre = require('hardhat');
const { INFINITE_BECH32_PREFIX, INFINITE_VALOPER_BECH32_PREFIX } = require('../common');

describe('Distribution – validator query methods', function () {
    const DIST_ADDRESS = '0x0000000000000000000000000000000000000801';
    const BECH32_ADDRESS = '0x0000000000000000000000000000000000000400'
    const VAL_OPER_HEX = '0xC6Fe5D33615a1C52c08018c47E8Bc53646A0E101'

    let distribution, bech32, signer;
    let valOperBech32;
    let valOperAccBech32;

    before(async () => {
        [signer] = await hre.ethers.getSigners();
        distribution = await hre.ethers.getContractAt('DistributionI', DIST_ADDRESS);
        bech32 = await hre.ethers.getContractAt('Bech32I', BECH32_ADDRESS);
        valOperBech32 = await bech32.getFunction('hexToBech32').staticCall(VAL_OPER_HEX, INFINITE_VALOPER_BECH32_PREFIX)
        valOperAccBech32 = await bech32.getFunction('hexToBech32').staticCall(VAL_OPER_HEX, INFINITE_BECH32_PREFIX)
    });

    it('validatorDistributionInfo returns current distribution info', async function () {
        const info = await distribution.validatorDistributionInfo(valOperBech32);
        console.log('validatorDistributionInfo:', info);
        // This method returns the *operator address* as a bech32 account-style string in this precompile.
        expect(info.operatorAddress).to.equal(valOperAccBech32);
        expect(info.selfBondRewards).to.be.an('array');
        expect(info.commission).to.be.an('array');
    });

    it('validatorSlashes returns slashing events (none expected)', async function () {
        const pageReq = { key: '0x', offset: 0, limit: 100, countTotal: true, reverse: false };
        const [slashes, pageResponse] = await distribution.validatorSlashes(
            valOperBech32,
            1,
            5,
            pageReq
        );
        console.log('validatorSlashes:', slashes, pageResponse);
        expect(slashes).to.be.an('array');
        expect(slashes.length).to.equal(Number(pageResponse.total.toString()));
    });

    it('delegatorValidators lists validators for delegator', async function () {
        const validators = await distribution.delegatorValidators(signer.address);
        console.log('delegatorValidators:', validators);
        console.log(validators)
        expect(validators).to.include(valOperBech32);
    });
});