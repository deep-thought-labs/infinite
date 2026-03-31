const { expect } = require('chai')
const { ethers } = require('hardhat')
const { findEvent, waitWithTimeout, RETRY_DELAY_FUNC, INFINITE_VALOPER_BECH32_PREFIX} = require('../common')

describe('Distribution – withdraw validator commission', function () {
    const DIST_ADDRESS = '0x0000000000000000000000000000000000000801'
    const BECH32_ADDRESS = '0x0000000000000000000000000000000000000400'
    const GAS_LIMIT    = 1_000_000

    let distribution, bech32, validator

    before(async () => {
        const signers   = await ethers.getSigners()
        validator       = signers[signers.length - 1]
        distribution    = await ethers.getContractAt('DistributionI', DIST_ADDRESS)
        bech32          = await ethers.getContractAt('Bech32I', BECH32_ADDRESS)
    })

    it('withdraws validator commission and emits proper event', async function () {
        const valHex        = '0x7cB61D4117AE31a12E393a1Cfa3BaC666481D02E'
        const valBech32     = await bech32.getFunction('hexToBech32').staticCall(valHex, INFINITE_VALOPER_BECH32_PREFIX)

        // 1) query commission before withdrawal
        const beforeRes = await distribution.validatorCommission(valBech32)
        const beforeAmt = beforeRes.length
            ? BigInt(beforeRes[0].amount.toString())
            : 0n

        // 2) withdraw commission
        const tx      = await distribution
            .connect(validator)
            .withdrawValidatorCommission(valBech32, { gasLimit: GAS_LIMIT })
        const receipt = await waitWithTimeout(tx, 20000, RETRY_DELAY_FUNC)

        // 3) parse the event
        const parsedEvt = findEvent(receipt.logs, distribution.interface, 'WithdrawValidatorCommission')
        expect(parsedEvt, 'event must be emitted').to.exist

        // 4) verify the indexed validatorAddress via topic hash
        const rawLog      = receipt.logs.find(log => {
            try { return distribution.interface.parseLog(log).name === 'WithdrawValidatorCommission' }
            catch { return false }
        })
        const expectedTopic = ethers.keccak256(ethers.toUtf8Bytes(valBech32))
        expect(rawLog.topics[1]).to.equal(expectedTopic)

        // 5) verify commission amount in event ≥ beforeAmt
        const commissionBn = parsedEvt.args.commission
        const commission   = BigInt(commissionBn.toString())
        expect(commission).to.be.gte(beforeAmt)

        // 6) query commission after withdrawal
        const afterRes = await distribution.validatorCommission(valBech32)
        const afterAmt = afterRes.length
            ? BigInt(afterRes[0].amount.toString())
            : 0n

        expect(afterAmt).to.be.lessThan(beforeAmt, 'Commission should be reduced')
    })
})