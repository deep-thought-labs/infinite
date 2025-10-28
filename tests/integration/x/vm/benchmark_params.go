package vm

import (
	"testing"

	"github.com/deep-thought-labs/infinite/x/vm/types"
)

func BenchmarkSetParams(b *testing.B) {
	suite := KeeperTestSuite{}
	suite.SetupTest()
	params := types.DefaultParams()

	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = suite.Network.App.GetEVMKeeper().SetParams(suite.Network.GetContext(), params)
	}
}

func BenchmarkGetParams(b *testing.B) {
	suite := KeeperTestSuite{}
	suite.SetupTest()

	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = suite.Network.App.GetEVMKeeper().GetParams(suite.Network.GetContext())
	}
}
