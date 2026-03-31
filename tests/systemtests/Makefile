#!/usr/bin/make -f

WAIT_TIME ?= 20s
TEST_ARGS ?=

test:
	go test -failfast -timeout=30m -mod=readonly -tags='system_test' -v ./... $(TEST_ARGS) --wait-time=$(WAIT_TIME) --binary evmd --chain-id local-4221 --bech32=infinite
