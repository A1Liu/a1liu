package utils

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
)

var (
	_, b, _, _         = runtime.Caller(0)
	projectRoot string = filepath.Dir(filepath.Dir(b))
)

func skipFramesLog(skipFrames int, msg string, args ...interface{}) {
	_, file, line, ok := runtime.Caller(skipFrames + 1)
	if !ok {
		fmt.Println("failed to log for some reason")
		os.Exit(1)
	}
	path, err := filepath.Rel(projectRoot, file)
	if err != nil {
		os.Exit(1)
	}

	fmt.Fprintf(os.Stderr, "%s:%v ", path, line)
	fmt.Fprintf(os.Stderr, msg, args...)
	fmt.Fprintf(os.Stderr, "\n")
}

func IFailIf(err error, msg string, args ...interface{}) {
	if err != nil {
		skipFramesLog(2, fmt.Sprintf("ERROR: "+msg+" ("+err.Error()+")", args...))
		os.Exit(1)
	}
}

func IFail(msg string, args ...interface{}) {
	skipFramesLog(2, "ERROR: "+fmt.Sprintf(msg, args...))
	os.Exit(1)
}

func ISuccess(msg string, args ...interface{}) {
	skipFramesLog(2, "SUCCESS: "+fmt.Sprintf(msg, args...))
}

func Log(msg string, args ...interface{}) {
	skipFramesLog(1, "LOG: "+fmt.Sprintf(msg, args...))
}

func IPrint(msg string, args ...interface{}) {
	skipFramesLog(2, "INFO: "+msg, args...)
}

func Print(msg string, args ...interface{}) {
	skipFramesLog(1, "INFO: "+msg, args...)
}

func Fail(msg string, args ...interface{}) {
	skipFramesLog(1, "ERROR: "+fmt.Sprintf(msg, args...))
	os.Exit(1)
}

func FailIf(err error, msg string, args ...interface{}) {
	if err != nil {
		skipFramesLog(1, fmt.Sprintf("ERROR: "+msg+" ("+err.Error()+")", args...))
		os.Exit(1)
	}
}
