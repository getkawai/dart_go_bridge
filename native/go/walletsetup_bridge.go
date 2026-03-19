package main

// #include <stdint.h>
// #include <stdlib.h>
import "C"

import "github.com/kawai-network/y/walletsetup"

type validationResult struct {
	Valid   bool   `json:"valid"`
	Message string `json:"message,omitempty"`
}

type passwordStrengthResult struct {
	Score int    `json:"score"`
	Label string `json:"label"`
	Color string `json:"color"`
}

//export WalletValidateMnemonicJSON
func WalletValidateMnemonicJSON(mnemonic *C.char) *C.char {
	if mnemonic == nil {
		return responseCString(jsonResponse{Ok: false, Error: "mnemonic is required"})
	}
	valid, message := walletsetup.ValidateMnemonicBasic(C.GoString(mnemonic))
	return responseCString(jsonResponse{Ok: true, Data: validationResult{Valid: valid, Message: message}})
}

//export WalletValidateKeystoreJSON
func WalletValidateKeystoreJSON(keystoreJSON *C.char) *C.char {
	if keystoreJSON == nil {
		return responseCString(jsonResponse{Ok: false, Error: "keystore JSON is required"})
	}
	valid, message := walletsetup.ValidateKeystoreJSON(C.GoString(keystoreJSON))
	return responseCString(jsonResponse{Ok: true, Data: validationResult{Valid: valid, Message: message}})
}

//export WalletValidatePrivateKeyJSON
func WalletValidatePrivateKeyJSON(privateKey *C.char) *C.char {
	if privateKey == nil {
		return responseCString(jsonResponse{Ok: false, Error: "private key is required"})
	}
	valid, message := walletsetup.ValidatePrivateKey(C.GoString(privateKey))
	return responseCString(jsonResponse{Ok: true, Data: validationResult{Valid: valid, Message: message}})
}

//export WalletPasswordStrengthJSON
func WalletPasswordStrengthJSON(password *C.char) *C.char {
	if password == nil {
		return responseCString(jsonResponse{Ok: false, Error: "password is required"})
	}
	score, label, color := walletsetup.PasswordStrength(C.GoString(password))
	return responseCString(jsonResponse{Ok: true, Data: passwordStrengthResult{
		Score: score,
		Label: label,
		Color: color,
	}})
}
