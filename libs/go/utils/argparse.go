package utils

import (
	"fmt"
	"reflect"
	"strconv"
	"strings"
)

type flagString string
type flagInt int
type flagBool bool

type FlagParser struct {
	Value FlagValue
}

type FlagValue interface {
	ParseFlag(string) error
}

func (b *flagString) ParseFlag(value string) error {
	*b = flagString(value)
	return nil
}

func (b *flagInt) ParseFlag(value string) error {
	i, err := strconv.Atoi(value)
	if err != nil {
		return err
	}

	*b = flagInt(i)
	return nil
}

func (b *flagBool) ParseFlag(value string) error {
	value = strings.ToLower(value)
	if value == "true" {
		*b = flagBool(true)
		return nil
	} else if value == "false" {
		*b = flagBool(false)
		return nil
	}
	return fmt.Errorf("value '%v' could not be coerced to a boolean", value)
}

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
			flags[fieldName] = FlagParser{(*flagString)(fieldPtr.(*string))}
			break
		case *string:
			flags[fieldName] = FlagParser{(*flagString)(fieldPtr.(*string))}
			break
		case *int:
			flags[fieldName] = FlagParser{(*flagInt)(fieldPtr.(*int))}
			break
		case *bool:
			flags[fieldName] = FlagParser{(*flagBool)(fieldPtr.(*bool))}
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
