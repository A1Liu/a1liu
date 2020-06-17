package main

import (
	"goPlaceholder/utils"
)

type Parser struct {
	Name string
}

func main() {
	var parser Parser
	utils.Print("%v\n", utils.ArgParse(&parser, "-Name", "hello"))

	utils.Print("%v\n", parser)

}
