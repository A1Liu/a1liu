package utils

import (
	"fmt"
	"os"
	"reflect"
	"strconv"
	"strings"
)

type FlagParser struct {
	Value FlagValue
}

type FlagValue interface {
	ParseFlag(string) error
}

type FlagString string
type FlagInt int
type FlagBool bool
type FlagStructNull struct {
	Value **interface{}
}
type FlagStringNull struct {
	Value **string
}
type FlagIntNull struct {
	Value **int
}
type FlagBoolNull struct {
	Value **bool
}

// Creates an argparser from a given struct
func ParseArgParser(parser interface{}) (map[string]FlagParser, error) {
	ptrValue := reflect.ValueOf(parser)
	if ptrValue.Kind() != reflect.Ptr {
		return nil, fmt.Errorf("given type '%v' is not a pointer", ptrValue.Kind())
	}

	value := reflect.Indirect(ptrValue)
	if value.Kind() != reflect.Struct {
		return nil, fmt.Errorf("given type '%v' is not a struct", value.Kind())
	}

	valueType := value.Type()
	flags := make(map[string]FlagParser)
	fieldCount := valueType.NumField()
	for i := 0; i < fieldCount; i++ {
		fieldName := valueType.Field(i).Name
		fieldPtr := value.Field(i).Addr().Interface()

		switch fieldPtr.(type) {
		case **string:
			flagString := FlagStringNull{fieldPtr.(**string)}
			flags[fieldName] = FlagParser{flagString}
			break
		case *string:
			flags[fieldName] = FlagParser{(*FlagString)(fieldPtr.(*string))}
			break
		case *int:
			flags[fieldName] = FlagParser{(*FlagInt)(fieldPtr.(*int))}
			break
		case *bool:
			flags[fieldName] = FlagParser{(*FlagBool)(fieldPtr.(*bool))}
			break
		default:
			fieldPtrTyped, ok := fieldPtr.(FlagValue)
			if !ok {
				return nil, fmt.Errorf("type '%v' doesn't implement FlagValue",
					valueType.Field(i).Type)
			}
			flags[fieldName] = FlagParser{fieldPtrTyped}
		}
	}

	return flags, nil
}

func ArgParseGlobal(parser interface{}) error {
	return ArgParse(parser, os.Args...)
}

// Parses the given arguments using the given struct
func ArgParse(parser interface{}, args ...string) error {
	flagParsers, err := ParseArgParser(parser)
	if err != nil {
		return err
	}

	idx := 0
	for ; idx < len(args); idx++ {
		arg := args[idx]
		if arg == "--" {
			idx++
			break
		}

		if strings.HasPrefix(arg, "-") {
			setter, ok := flagParsers[arg[1:]]
			if !ok {
				return fmt.Errorf("flag '%v' not recognized", arg)
			}

			idx++
			if idx == len(args) {
				return fmt.Errorf("flag '%v' requires a value", arg)
			}

			value := args[idx]
			err := setter.Value.ParseFlag(value)
			if err != nil {
				return err
			}
		}

	}
	return nil
}

func (s FlagStringNull) ParseFlag(value string) error {
	*s.Value = &value
	return nil
}

func (b *FlagString) ParseFlag(value string) error {
	*b = FlagString(value)
	return nil
}

func (b *FlagInt) ParseFlag(value string) error {
	i, err := strconv.Atoi(value)
	if err != nil {
		return err
	}

	*b = FlagInt(i)
	return nil
}

func (b *FlagBool) ParseFlag(value string) error {
	value = strings.ToLower(value)
	if value == "true" {
		*b = FlagBool(true)
		return nil
	} else if value == "false" {
		*b = FlagBool(false)
		return nil
	}
	return fmt.Errorf("value '%v' could not be coerced to a boolean", value)
}
