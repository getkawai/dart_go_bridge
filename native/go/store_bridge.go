package main

// #include <stdint.h>
// #include <stdlib.h>
import "C"

import (
	"context"
	"encoding/json"
	"errors"
	"math/big"
	"sync"
	"sync/atomic"

	"github.com/kawai-network/x/store"
)

type jsonResponse struct {
	Ok     bool        `json:"ok"`
	Error  string      `json:"error,omitempty"`
	Data   interface{} `json:"data,omitempty"`
	Handle uint64      `json:"handle,omitempty"`
}

var (
	storeHandles   = map[uint64]*store.KVStore{}
	storeHandlesMu sync.RWMutex
	storeSeq       uint64
)

func nextStoreHandle(s *store.KVStore) uint64 {
	handle := atomic.AddUint64(&storeSeq, 1)
	storeHandlesMu.Lock()
	storeHandles[handle] = s
	storeHandlesMu.Unlock()
	return handle
}

func getStoreHandle(handle uint64) (*store.KVStore, error) {
	storeHandlesMu.RLock()
	s := storeHandles[handle]
	storeHandlesMu.RUnlock()
	if s == nil {
		return nil, errors.New("invalid store handle")
	}
	return s, nil
}

func deleteStoreHandle(handle uint64) {
	storeHandlesMu.Lock()
	delete(storeHandles, handle)
	storeHandlesMu.Unlock()
}

func responseCString(resp jsonResponse) *C.char {
	payload, _ := json.Marshal(resp)
	return C.CString(string(payload))
}

func parseBigInt(amount string) (*big.Int, error) {
	v := new(big.Int)
	if _, ok := v.SetString(amount, 10); !ok {
		return nil, errors.New("invalid amount")
	}
	return v, nil
}

//export StoreNewJSON
func StoreNewJSON(_ *C.char) *C.char {
	kv, err := store.NewMultiNamespaceKVStore()
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}

	handle := nextStoreHandle(kv)
	return responseCString(jsonResponse{Ok: true, Handle: handle})
}

//export StoreFree
func StoreFree(handle C.uint64_t) {
	deleteStoreHandle(uint64(handle))
}

//export StoreGetUserBalanceJSON
func StoreGetUserBalanceJSON(handle C.uint64_t, address *C.char) *C.char {
	if address == nil {
		return responseCString(jsonResponse{Ok: false, Error: "address is required"})
	}
	kv, err := getStoreHandle(uint64(handle))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	balance, err := kv.GetUserBalance(context.Background(), C.GoString(address))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	return responseCString(jsonResponse{Ok: true, Data: balance})
}

//export StoreAddBalanceJSON
func StoreAddBalanceJSON(handle C.uint64_t, address *C.char, amount *C.char) *C.char {
	if address == nil || amount == nil {
		return responseCString(jsonResponse{Ok: false, Error: "address and amount are required"})
	}
	kv, err := getStoreHandle(uint64(handle))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	v, err := parseBigInt(C.GoString(amount))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	if err := kv.AddBalanceAtomic(context.Background(), C.GoString(address), v); err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	return responseCString(jsonResponse{Ok: true})
}

//export StoreDeductBalanceJSON
func StoreDeductBalanceJSON(handle C.uint64_t, address *C.char, amount *C.char) *C.char {
	if address == nil || amount == nil {
		return responseCString(jsonResponse{Ok: false, Error: "address and amount are required"})
	}
	kv, err := getStoreHandle(uint64(handle))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	v, err := parseBigInt(C.GoString(amount))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	if err := kv.DeductBalanceAtomic(context.Background(), C.GoString(address), v); err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	return responseCString(jsonResponse{Ok: true})
}

//export StoreTransferBalanceJSON
func StoreTransferBalanceJSON(handle C.uint64_t, from *C.char, to *C.char, amount *C.char) *C.char {
	if from == nil || to == nil || amount == nil {
		return responseCString(jsonResponse{Ok: false, Error: "from, to, and amount are required"})
	}
	kv, err := getStoreHandle(uint64(handle))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	v, err := parseBigInt(C.GoString(amount))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	if err := kv.TransferBalanceAtomic(context.Background(), C.GoString(from), C.GoString(to), v); err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	return responseCString(jsonResponse{Ok: true})
}

//export StoreCreateAPIKeyJSON
func StoreCreateAPIKeyJSON(handle C.uint64_t, address *C.char) *C.char {
	if address == nil {
		return responseCString(jsonResponse{Ok: false, Error: "address is required"})
	}
	kv, err := getStoreHandle(uint64(handle))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	key, err := kv.CreateAPIKey(context.Background(), C.GoString(address))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	return responseCString(jsonResponse{Ok: true, Data: key})
}

//export StoreValidateAPIKeyJSON
func StoreValidateAPIKeyJSON(handle C.uint64_t, apiKey *C.char) *C.char {
	if apiKey == nil {
		return responseCString(jsonResponse{Ok: false, Error: "apiKey is required"})
	}
	kv, err := getStoreHandle(uint64(handle))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	address, err := kv.ValidateAPIKey(context.Background(), C.GoString(apiKey))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	return responseCString(jsonResponse{Ok: true, Data: address})
}

//export StoreGetContributorJSON
func StoreGetContributorJSON(handle C.uint64_t, address *C.char) *C.char {
	if address == nil {
		return responseCString(jsonResponse{Ok: false, Error: "address is required"})
	}
	kv, err := getStoreHandle(uint64(handle))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	contributor, err := kv.GetContributor(context.Background(), C.GoString(address))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	return responseCString(jsonResponse{Ok: true, Data: contributor})
}

//export StoreListContributorsJSON
func StoreListContributorsJSON(handle C.uint64_t) *C.char {
	kv, err := getStoreHandle(uint64(handle))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	contributors, err := kv.ListContributors(context.Background())
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}
	return responseCString(jsonResponse{Ok: true, Data: contributors})
}
