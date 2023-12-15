package main

import (
	"os"
	"path"
	"strings"
)

var base = "/"
var output = ""
var seenPaths = make(map[string]struct{}, 64)

func addPath(path string) {
	if _, ok := seenPaths[path]; ok {
		return
	}

	seenPaths[path] = struct{}{}
	if strings.HasPrefix(path, "~/") {
		output += base
		path = path[2:]
	}

	output += path
	output += ":"
}

func main() {
	base = os.Args[1]
	envPath, ok := os.LookupEnv("PATH")
	if !ok {
		panic("missing PATH variable")
	}

	cfgDir, ok := os.LookupEnv("CFG_DIR")
	if !ok {
		panic("missing CFG_DIR variable")
	}

	{
		localPath := path.Join(cfgDir, "local", "path")
		addPath(localPath)
	}

	// linux gopath
	addPath("/usr/local/go/bin")

	// gopath
	addPath("~/go")
	addPath("~/go/bin")

	addPath("/opt/homebrew/bin")
	addPath("/opt/homebrew/Cellar/llvm/14.0.6/bin:$PATH")

	addPath("~/.rbenv/bin")

	// MacPorts
	addPath("/opt/local/bin")
	addPath("/opt/local/sbin")

	{
		for _, p := range strings.Split(envPath, ":") {
			addPath(p)
		}
	}

	print(output)
}
