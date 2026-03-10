package main

// #include <stdint.h>
// #include <stdlib.h>
import "C"

import (
	"unsafe"

	"github.com/getkawai/tools/mobilebridge"
)

//export GoWebSearchJSON
func GoWebSearchJSON(query *C.char) *C.char {
	if query == nil {
		return nil
	}
	out := mobilebridge.WebSearchJSON(C.GoString(query))
	return C.CString(out)
}

//export GoFreeString
func GoFreeString(ptr *C.char) {
	if ptr == nil {
		return
	}
	C.free(unsafe.Pointer(ptr))
}

func main() {}
