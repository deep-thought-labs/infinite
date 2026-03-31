//go:build system_test

package chainupgrade

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"github.com/tidwall/gjson"

	"github.com/cosmos/evm/tests/systemtests/clients"
	"github.com/cosmos/evm/tests/systemtests/suite"

	systest "github.com/cosmos/cosmos-sdk/testutil/systemtests"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/address"
)

const (
	// Must be high enough that gov voting_period can elapse (tally) before this height: the upgrade
	// module halts block production at upgradeHeight, so if height is reached while still in
	// VOTING_PERIOD, awaitGovProposalStatus never sees PASSED ("no block within …").
	// Keep this modest (not ~100): after PASSED the chain is often ~height 15–25; needing 80+ more
	// blocks stresses Docker/CI and makes failures hard to distinguish from a stalled validator set.
	upgradeHeight int64 = 45
	upgradeName         = "v0.1.10-to-v0.1.12" // must match UpgradeNameSystemTest in infinited/upgrades.go

	// legacyHaltHeight caps the legacy node; must stay well above upgradeHeight (safety net only;
	// the real stop for the legacy binary is upgradeHeight via x/upgrade).
	legacyHaltHeight = upgradeHeight + 200

	chainUpgradeChainID = "local-4221"
	// Matches infinited testnet --single-host when generating init-files (memo nodeID@127.0.0.1:port).
	testnetP2PBasePort = 16656

	// Node0 RPC for the default systemtests testnet (matches systemtests.SystemUnderTest).
	defaultSutRPCAddr = "tcp://localhost:26657"
	// Wall time to reach upgradeHeight-1: many blocks × timeout_commit; avoid sut.AwaitBlockHeight
	// (inner AwaitNextBlock uses blockTime×6 ≈ 18s and can flake under Docker/CI).
	awaitPreUpgradeHeightDeadline = 15 * time.Minute
)

// RunChainUpgrade exercises an on-chain software upgrade using the injected shared suite.
//
// Genesis path (option A): after the legacy binary produces testnet init-files, we apply
// scripts/customize_genesis.sh with --network upgrade-test (see scripts/genesis-configs/upgrade-test.json).
// The script aligns bank/gov/EVM/staking/mint to `drop` but leaves legacy gentx in `genutil.gen_txs`
// (signed for `stake`) inconsistent with the new bond denom. We therefore:
//  1. Read each validator self-delegation amount from the embedded gentx (numeric amount only).
//  2. Clear `app_state.genutil.gen_txs` (requires jq).
//  3. Replicate genesis to every node, run `evmd genesis gentx` per validator with the same amounts in `drop`,
//     matching testnet commission / moniker / p2p memo inputs.
//  4. Place all gentx JSON under node0's config/gentx and run `evmd genesis collect-gentxs --home node0`.
//  5. Copy the final genesis.json from node0 to the other validators.
//
// Do not edit gentx JSON by hand; regenerate and collect instead.
func RunChainUpgrade(t *testing.T, base *suite.BaseTestSuite) {
	t.Helper()

	base.SetupTest(t)
	sut := base.SystemUnderTest

	// Scenario:
	// start a legacy chain with some state
	// when a chain upgrade proposal is executed
	// then the chain upgrades successfully
	sut.StopChain()

	currentBranchBinary := sut.ExecBinary()
	currentInitializer := sut.TestnetInitializer()

	legacyBinary := systest.WorkDir + "/binaries/v0.5/evmd"
	systest.Sut.SetExecBinary(legacyBinary)
	systest.Sut.SetTestnetInitializer(systest.InitializerWithBinary(legacyBinary, systest.Sut))
	systest.Sut.SetupChain()

	repoRoot := filepath.Clean(filepath.Join(systest.WorkDir, "..", ".."))
	genesisPath := filepath.Join(sut.NodeDir(0), "config", "genesis.json")
	scriptPath := filepath.Join(repoRoot, "scripts", "customize_genesis.sh")
	cmd := exec.Command("bash", scriptPath, genesisPath, "--network", "upgrade-test", "--skip-accounts")
	cmd.Dir = repoRoot
	cmd.Env = append(os.Environ(), "INFINITED_BIN="+currentBranchBinary)
	out, err := cmd.CombinedOutput()
	require.NoError(t, err, "customize_genesis.sh (upgrade-test): %s", string(out))

	genesisBeforeGentx, err := os.ReadFile(genesisPath)
	require.NoError(t, err)
	selfDelegation := gentxSelfDelegationCoins(t, genesisBeforeGentx, sut.NodesCount())

	stripGenutilGenTxs(t, genesisPath)

	copyCustomizedGenesisToAllNodes(t, sut)
	regenerateGentxsWithBaseDenom(t, sut, legacyBinary, selfDelegation)
	copyCustomizedGenesisToAllNodes(t, sut)
	// SetupChain only copies node0's keyring to testnet/keyring-test; CLIWrapper uses that dir as --home.
	// Merge every validator keyring so GetKeyAddr("node1").. work for gov votes (matches ResetChain's restoreOriginalKeyring).
	mergeAllValidatorKeyringsForCLI(t, sut)
	sut.MarkDirty()

	sut.StartChain(t, fmt.Sprintf("--halt-height=%d", legacyHaltHeight), "--chain-id=local-4221", "--minimum-gas-prices=0.00"+clients.NativeBaseDenom)

	cli := systest.NewCLIWrapper(t, sut, systest.Verbose)
	govAddr := sdk.AccAddress(address.Module("gov")).String()
	depositCoin := "100000000" + clients.NativeBaseDenom
	feeCoin := "10000000000000000000" + clients.NativeBaseDenom
	// submit upgrade proposal
	proposal := fmt.Sprintf(`
{
 "messages": [
  {
   "@type": "/cosmos.upgrade.v1beta1.MsgSoftwareUpgrade",
   "authority": %q,
   "plan": {
    "name": %q,
    "height": "%d"
   }
  }
 ],
 "metadata": "ipfs://CID",
 "deposit": %q,
 "title": "my upgrade",
 "summary": "testing"
}`, govAddr, upgradeName, upgradeHeight, depositCoin)
	rsp := cli.SubmitGovProposal(proposal, "--fees="+feeCoin, "--from=node0")
	systest.RequireTxSuccess(t, rsp)
	raw := cli.CustomQuery("q", "gov", "proposals", "--depositor", cli.GetKeyAddr("node0"))
	proposals := gjson.Get(raw, "proposals.#.id").Array()
	require.NotEmpty(t, proposals, raw)
	proposalID := proposals[len(proposals)-1].String()

	for i := range sut.NodesCount() {
		sut.Logf("Voting: validator %d\n", i)
		rsp := cli.Run("tx", "gov", "vote", proposalID, "yes", "--fees="+feeCoin, "--from", cli.GetKeyAddr(fmt.Sprintf("node%d", i)))
		systest.RequireTxSuccess(t, rsp)
	}

	// Tally runs after voting_end (not when the last vote lands). Wait explicitly so we do not assert PASSED
	// at upgradeHeight-1 while the proposal is still PROPOSAL_STATUS_VOTING_PERIOD.
	awaitGovProposalStatus(t, cli, proposalID, "PROPOSAL_STATUS_PASSED", 2*time.Minute)

	awaitCometBlockHeightHTTP(t, defaultSutRPCAddr, upgradeHeight-1, awaitPreUpgradeHeightDeadline)
	t.Logf("current_height (suite): %d\n", sut.CurrentHeight())
	raw = cli.CustomQuery("q", "gov", "proposal", proposalID)
	proposalStatus := gjson.Get(raw, "proposal.status").String()
	require.Equal(t, "PROPOSAL_STATUS_PASSED", proposalStatus, raw)

	t.Log("waiting for upgrade info")
	sut.AwaitUpgradeInfo(t)
	sut.StopChain()

	t.Log("Upgrade height was reached. Upgrading chain")
	sut.SetExecBinary(currentBranchBinary)
	sut.SetTestnetInitializer(currentInitializer)
	sut.StartChain(t, "--chain-id=local-4221", "--mempool.max-txs=0")

	require.Equal(t, upgradeHeight+1, sut.CurrentHeight())

	// smoke test to make sure the chain still functions.
	cli = systest.NewCLIWrapper(t, sut, systest.Verbose)
	to := cli.GetKeyAddr("node1")
	from := cli.GetKeyAddr("node0")
	got := cli.Run("tx", "bank", "send", from, to, "1"+clients.NativeBaseDenom, "--from=node0", "--fees="+feeCoin, "--chain-id=local-4221")
	systest.RequireTxSuccess(t, got)
}

// gentxSelfDelegationCoins returns one "amount" string per validator gentx (e.g. 100... + NativeBaseDenom),
// parsed from the legacy embedded gentx before those txs are cleared.
func gentxSelfDelegationCoins(t *testing.T, genesisJSON []byte, n int) []string {
	t.Helper()
	out := make([]string, n)
	for i := 0; i < n; i++ {
		base := fmt.Sprintf("app_state.genutil.gen_txs.%d.body.messages.0", i)
		amt := gjson.GetBytes(genesisJSON, base+".value.amount").String()
		if amt == "" {
			amt = gjson.GetBytes(genesisJSON, base+".amount.amount").String()
		}
		require.NotEmpty(t, amt, "could not read self-delegation amount for gentx %d (genesis tx shape may have changed)", i)
		out[i] = amt + clients.NativeBaseDenom
	}
	return out
}

func stripGenutilGenTxs(t *testing.T, genesisPath string) {
	t.Helper()
	out, err := exec.Command("jq", ".app_state.genutil.gen_txs = []", genesisPath).CombinedOutput()
	require.NoError(t, err, "jq (install jq or fix genesis path): %s", string(out))
	require.NoError(t, os.WriteFile(genesisPath, out, 0o644))
}

func regenerateGentxsWithBaseDenom(t *testing.T, sut *systest.SystemUnderTest, legacyBinary string, selfDelegation []string) {
	t.Helper()
	n := sut.NodesCount()
	require.Len(t, selfDelegation, n)

	node0Gentx := filepath.Join(sut.NodeDir(0), "config", "gentx")
	require.NoError(t, os.RemoveAll(node0Gentx))
	require.NoError(t, os.MkdirAll(node0Gentx, 0o700))

	for i := 0; i < n; i++ {
		home := sut.NodeDir(i)
		gentxDir := filepath.Join(home, "config", "gentx")
		require.NoError(t, os.RemoveAll(gentxDir))
		require.NoError(t, os.MkdirAll(gentxDir, 0o700))

		args := []string{
			"genesis", "gentx",
			"--chain-id=" + chainUpgradeChainID,
			"--home=" + home,
			"--keyring-backend=test",
			"--commission-rate=1.0",
			"--commission-max-rate=1.0",
			"--commission-max-change-rate=1.0",
			"--min-self-delegation=1",
			"--ip=127.0.0.1",
			fmt.Sprintf("--p2p-port=%d", testnetP2PBasePort+i),
			fmt.Sprintf("--moniker=node%d", i),
			"--gas=400000",
			"--fees=0" + clients.NativeBaseDenom,
			fmt.Sprintf("node%d", i),
			selfDelegation[i],
		}
		gtx := exec.Command(legacyBinary, args...)
		gtx.Env = os.Environ()
		gtxOut, gtxErr := gtx.CombinedOutput()
		require.NoError(t, gtxErr, "genesis gentx node%d: %s", i, string(gtxOut))

		matches, globErr := filepath.Glob(filepath.Join(gentxDir, "gentx-*.json"))
		require.NoError(t, globErr)
		require.Len(t, matches, 1, "expected one gentx-*.json under %s", gentxDir)
		dst := filepath.Join(node0Gentx, filepath.Base(matches[0]))
		raw, readErr := os.ReadFile(matches[0])
		require.NoError(t, readErr)
		require.NoError(t, os.WriteFile(dst, raw, 0o644))
	}

	collect := exec.Command(legacyBinary, "genesis", "collect-gentxs", "--home="+sut.NodeDir(0))
	collect.Env = os.Environ()
	collectOut, collectErr := collect.CombinedOutput()
	require.NoError(t, collectErr, "genesis collect-gentxs: %s", string(collectOut))
}

// cometStatusHTTPURL maps the systemtests RPC address (tcp://host:port) to a plain HTTP /status URL.
func cometStatusHTTPURL(rpcTCP string) string {
	s := strings.TrimPrefix(rpcTCP, "tcp://")
	s = strings.ReplaceAll(s, "localhost", "127.0.0.1")
	return "http://" + s + "/status"
}

// awaitCometBlockHeightHTTP polls GET /status over HTTP until LatestBlockHeight >= target.
// We avoid a second Comet RPC websocket client here: the shared suite already holds a websocket
// subscription to node0; an extra client has been observed to correlate with stalled height in CI.
// Plain HTTP polling does not contend with that subscription path.
func awaitCometBlockHeightHTTP(t *testing.T, rpcTCP string, target int64, deadline time.Duration) {
	t.Helper()
	url := cometStatusHTTPURL(rpcTCP)
	httpClient := &http.Client{Timeout: 12 * time.Second}
	until := time.Now().Add(deadline)
	var lastH int64
	lastProgressLog := time.Now()
	for time.Now().Before(until) {
		resp, err := httpClient.Get(url)
		require.NoError(t, err)
		body, rerr := io.ReadAll(resp.Body)
		require.NoError(t, rerr)
		require.NoError(t, resp.Body.Close())
		require.Equal(t, http.StatusOK, resp.StatusCode, "GET %s: %s", url, string(body))
		lastH = gjson.GetBytes(body, "result.sync_info.latest_block_height").Int()
		if lastH >= target {
			t.Logf("comet height reached %d (target >= %d)", lastH, target)
			return
		}
		if time.Since(lastProgressLog) >= 30*time.Second {
			t.Logf("still awaiting comet height: %d (need >= %d)", lastH, target)
			lastProgressLog = time.Now()
		}
		time.Sleep(400 * time.Millisecond)
	}
	t.Fatalf("timeout waiting for comet height >= %d (last %d)", target, lastH)
}

func awaitGovProposalStatus(t *testing.T, cli *systest.CLIWrapper, proposalID, want string, timeout time.Duration) {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		raw := cli.CustomQuery("q", "gov", "proposal", proposalID)
		st := gjson.Get(raw, "proposal.status").String()
		if st == want {
			return
		}
		require.NotEqual(t, "PROPOSAL_STATUS_REJECTED", st, "proposal rejected: %s", raw)
		// Avoid sut.AwaitNextBlock: it enforces the global --wait-time (e.g. ~18s) and fails if the
		// next block is slow; the chain keeps producing blocks while we poll.
		time.Sleep(3 * time.Second)
	}
	raw := cli.CustomQuery("q", "gov", "proposal", proposalID)
	require.Equal(t, want, gjson.Get(raw, "proposal.status").String(), "timeout waiting for gov proposal %s: %s", want, raw)
}

func copyCustomizedGenesisToAllNodes(t *testing.T, sut *systest.SystemUnderTest) {
	t.Helper()
	src := filepath.Join(sut.NodeDir(0), "config", "genesis.json")
	data, err := os.ReadFile(src)
	require.NoError(t, err)
	for i := 1; i < sut.NodesCount(); i++ {
		dest := filepath.Join(sut.NodeDir(i), "config", "genesis.json")
		require.NoError(t, os.WriteFile(dest, data, 0o644))
	}
}

// cliSharedKeyringDir is the testnet-level keyring directory used by systemtests.CLIWrapper (--home testnet).
func cliSharedKeyringDir(sut *systest.SystemUnderTest) string {
	return filepath.Join(filepath.Dir(filepath.Dir(sut.NodeDir(0))), "keyring-test")
}

func mergeAllValidatorKeyringsForCLI(t *testing.T, sut *systest.SystemUnderTest) {
	t.Helper()
	dest := cliSharedKeyringDir(sut)
	require.NoError(t, os.RemoveAll(dest))
	require.NoError(t, os.MkdirAll(dest, 0o750))
	for i := range sut.NodesCount() {
		src := filepath.Join(sut.NodeDir(i), "keyring-test")
		entries, err := os.ReadDir(src)
		require.NoError(t, err, "read keyring %s", src)
		for _, e := range entries {
			if e.IsDir() {
				continue
			}
			inPath := filepath.Join(src, e.Name())
			outPath := filepath.Join(dest, e.Name())
			in, oerr := os.Open(inPath)
			require.NoError(t, oerr)
			out, cerr := os.Create(outPath)
			require.NoError(t, cerr)
			_, cerr = io.Copy(out, in)
			require.NoError(t, cerr)
			require.NoError(t, in.Close())
			require.NoError(t, out.Close())
		}
	}
}
