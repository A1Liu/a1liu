package main

import (
	"goPlaceholder/utils"
)

type Hello struct {
	Hello string
}

func (h *Hello) ParseFlag(hello string) error {
	utils.Print("hi\n")
	h.Hello = "what"
	return nil
}

type Parser struct {
	Name       Hello
	Occupation *string
}

func main() {
	var parser Parser
	utils.Print("%v\n", utils.ArgParse(&parser, "-Name", "hello", "-Occupation", "goodbye"))

	utils.Print("%v\n", parser.Name)
	utils.Print("%v\n", *parser.Occupation)
}
