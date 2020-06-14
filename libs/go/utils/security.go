package utils

import (
	"crypto"
	"encoding/base64"
	_ "golang.org/x/crypto/sha3"
	"math/rand"
	"strconv"
	"time"
	"unsafe"
)

const letterBytes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
const (
	letterIdxBits = 6                    // 6 bits to represent a letter index
	letterIdxMask = 1<<letterIdxBits - 1 // All 1-bits, as many as letterIdxBits
	letterIdxMax  = 63 / letterIdxBits   // # of letter indices fitting in 63 bits
)

var src = rand.NewSource(time.Now().UnixNano())

func RandomString(n int) string {
	b := make([]byte, n)
	// A src.Int63() generates 63 random bits, enough for letterIdxMax characters!
	for i, cache, remain := n-1, src.Int63(), letterIdxMax; i >= 0; {
		if remain == 0 {
			cache, remain = src.Int63(), letterIdxMax
		}
		if idx := int(cache & letterIdxMask); idx < len(letterBytes) {
			b[i] = letterBytes[idx]
			i--
		}
		cache >>= letterIdxBits
		remain--
	}

	return *(*string)(unsafe.Pointer(&b))
}

func RandomUint64() uint64 {
	return uint64(src.Int63())
}

func HashPassword(salt uint64, password string) string {
	hash := crypto.SHA3_512.New()
	salted := password + strconv.FormatUint(salt, 10)
	hash.Write([]byte(salted))
	output := hash.Sum(nil)
	return base64.StdEncoding.EncodeToString(output)
}
