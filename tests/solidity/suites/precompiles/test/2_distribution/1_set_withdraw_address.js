const {expect} = require('chai');
const hre = require('hardhat');
const { findEvent, waitWithTimeout, RETRY_DELAY_FUNC, INFINITE_BECH32_PREFIX } = require('../common');

describe('Distribution – set withdraw address', function () {
    const DIST_ADDRESS = '0x0000000000000000000000000000000000000801';
    const BECH32_ADDRESS = '0x0000000000000000000000000000000000000400'
    const GAS_LIMIT = 1_000_000;

    let distribution, bech32, signer;

    before(async () => {
        [signer] = await hre.ethers.getSigners();
        distribution = await hre.ethers.getContractAt('DistributionI', DIST_ADDRESS);
        bech32 = await hre.ethers.getContractAt('Bech32I', BECH32_ADDRESS)
    });

    it('should set withdraw address and emit SetWithdrawerAddress event', async function () {
        // Derive a valid bech32 address (checksum must match the HRP).
        const newWithdrawHex = '0x498B5AeC5D439b733dC2F58AB489783A23FB26dA'
        const newWithdrawAddress = await bech32.getFunction('hexToBech32').staticCall(newWithdrawHex, INFINITE_BECH32_PREFIX)
        const tx = await distribution
            .connect(signer)
            .setWithdrawAddress(signer.address, newWithdrawAddress, {gasLimit: GAS_LIMIT});
        const receipt = await waitWithTimeout(tx, 60000, RETRY_DELAY_FUNC);
        console.log('SetWithdrawAddress tx hash:', receipt.hash);

        const evt = findEvent(receipt.logs, distribution.interface, 'SetWithdrawerAddress');
        expect(evt, 'SetWithdrawerAddress event must be emitted').to.exist;
        expect(evt.args.caller).to.equal(signer.address);
        expect(evt.args.withdrawerAddress).to.equal(newWithdrawAddress);

        const withdrawer = await distribution.delegatorWithdrawAddress(signer.address);
        console.log('Withdraw address:', withdrawer);
        expect(withdrawer).to.equal(newWithdrawAddress);
    });
});