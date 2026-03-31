const { expect } = require('chai');
const hre = require('hardhat');
const { findEvent, waitWithTimeout, RETRY_DELAY_FUNC, BECH32_PRECOMPILE_ADDRESS, INFINITE_VALOPER_BECH32_PREFIX } = require('../common');

describe('Distribution – deposit validator rewards pool', function () {
    this.timeout(120000);
    const DIST_ADDRESS = '0x0000000000000000000000000000000000000801';
    const BECH32_ADDRESS = '0x0000000000000000000000000000000000000400'
    const GAS_LIMIT = 1_000_000;
    const VAL_HEX = '0x7cB61D4117AE31a12E393a1Cfa3BaC666481D02E';

    let distribution, bech32, signer;
    let valBech32;

    before(async () => {
        [signer] = await hre.ethers.getSigners();
        distribution = await hre.ethers.getContractAt('DistributionI', DIST_ADDRESS);
        bech32 = await hre.ethers.getContractAt('Bech32I', BECH32_ADDRESS)
        valBech32 = await bech32.getFunction('hexToBech32').staticCall(VAL_HEX, INFINITE_VALOPER_BECH32_PREFIX)
    });

    it('deposits rewards and emits DepositValidatorRewardsPool event', async function () {
        const coin = { denom: 'drop', amount: hre.ethers.parseEther('0.1') };

        const beforeRewards = await distribution.validatorOutstandingRewards(valBech32);
        const beforeCoin = beforeRewards.find(c => c.denom === coin.denom);
        const start = beforeCoin ? BigInt(beforeCoin.amount.toString()) : 0n;

        const balanceBefore = await hre.ethers.provider.getBalance(signer.address);
        console.log('User balance before deposit:', balanceBefore.toString());

        const tx = await distribution
            .connect(signer)
            .depositValidatorRewardsPool(signer.address, valBech32, [coin], { gasLimit: GAS_LIMIT });
        const receipt = await waitWithTimeout(tx, 60000, RETRY_DELAY_FUNC);
        console.log('DepositValidatorRewardsPool tx hash:', receipt.hash);

        const balanceAfter = await hre.ethers.provider.getBalance(signer.address);
        console.log('User balance after deposit:', balanceAfter.toString());

        const evt = findEvent(receipt.logs, distribution.interface, 'DepositValidatorRewardsPool');
        expect(evt, 'DepositValidatorRewardsPool event must be emitted').to.exist;
        expect(evt.args.depositor).to.equal(signer.address);
        expect(evt.args.validatorAddress).to.equal(VAL_HEX);
        expect(evt.args.denom).to.equal(coin.denom);
        expect(evt.args.amount.toString()).to.equal(coin.amount.toString());

        const gasUsed = receipt.gasUsed * receipt.gasPrice;
        const expectedBalance = balanceBefore - BigInt(coin.amount.toString()) - gasUsed;
        expect(balanceAfter).to.equal(expectedBalance, 'User balance should decrease by deposit amount plus gas costs');
        console.log('finished balance checks');

        const afterRewards = await distribution.validatorOutstandingRewards(valBech32);
        const afterCoin = afterRewards.find(c => c.denom === coin.denom);
        const end = afterCoin ? BigInt(afterCoin.amount.toString()) : 0n;
        expect(end).to.gte(start + BigInt(coin.amount.toString()));
    });
});
