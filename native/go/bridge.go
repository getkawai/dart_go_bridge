package main

// #include <stdint.h>
// #include <stdlib.h>
import "C"

import "unsafe"

//export GoFreeString
func GoFreeString(ptr *C.char) {
	if ptr == nil {
		return
	}
	C.free(unsafe.Pointer(ptr))
}

func main() {}
