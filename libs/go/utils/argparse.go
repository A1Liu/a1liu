package utils

import (
	"fmt"
	"os"
	"reflect"
	"strconv"
	"strings"
)

type FlagParser struct {
	Value         FlagValue
	RequiresValue bool
}

type FlagValue interface {
	ParseFlag(string) error
}

type FlagString string
type FlagStringNull struct {
	Value **string
}

type FlagInt int
type FlagInt8 int8
type FlagInt16 int16
type FlagInt32 int32
type FlagInt64 int64
type FlagIntNull struct {
	Value **int
}
type FlagInt8Null struct {
	Value **int8
}
type FlagInt16Null struct {
	Value **int16
}
type FlagInt32Null struct {
	Value **int32
}
type FlagInt64Null struct {
	Value **int64
}

type FlagUInt uint
type FlagUInt8 uint8
type FlagUInt16 uint16
type FlagUInt32 uint32
type FlagUInt64 uint64
type FlagUIntNull struct {
	Value **uint
}
type FlagUInt8Null struct {
	Value **uint8
}
type FlagUInt16Null struct {
	Value **uint16
}
type FlagUInt32Null struct {
	Value **uint32
}
type FlagUInt64Null struct {
	Value **uint64
}

type FlagBool bool

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
		fieldEntry := valueType.Field(i)
		fieldName := fieldEntry.Name
		fieldPtr := value.Field(i).Addr().Interface()

		switch fieldPtr.(type) {
		case *int:
			flags[fieldName] = FlagParser{(*FlagInt)(fieldPtr.(*int)), true}
			break
		case *int8:
			flags[fieldName] = FlagParser{(*FlagInt8)(fieldPtr.(*int8)), true}
			break
		case *int16:
			flags[fieldName] = FlagParser{(*FlagInt16)(fieldPtr.(*int16)), true}
			break
		case *int32:
			flags[fieldName] = FlagParser{(*FlagInt32)(fieldPtr.(*int32)), true}
			break
		case *int64:
			flags[fieldName] = FlagParser{(*FlagInt64)(fieldPtr.(*int64)), true}
			break

		case **int:
			flagInt := FlagIntNull{fieldPtr.(**int)}
			flags[fieldName] = FlagParser{flagInt, true}
			break
		case **int8:
			flagInt := FlagInt8Null{fieldPtr.(**int8)}
			flags[fieldName] = FlagParser{flagInt, true}
			break
		case **int16:
			flagInt := FlagInt16Null{fieldPtr.(**int16)}
			flags[fieldName] = FlagParser{flagInt, true}
			break
		case **int32:
			flagInt := FlagInt8Null{fieldPtr.(**int8)}
			flags[fieldName] = FlagParser{flagInt, true}
			break
		case **int64:
			flagInt := FlagInt64Null{fieldPtr.(**int64)}
			flags[fieldName] = FlagParser{flagInt, true}
			break

		case *uint:
			flags[fieldName] = FlagParser{(*FlagUInt)(fieldPtr.(*uint)), true}
			break
		case *uint8:
			flags[fieldName] = FlagParser{(*FlagUInt8)(fieldPtr.(*uint8)), true}
			break
		case *uint16:
			flags[fieldName] = FlagParser{(*FlagUInt16)(fieldPtr.(*uint16)), true}
			break
		case *uint32:
			flags[fieldName] = FlagParser{(*FlagUInt32)(fieldPtr.(*uint32)), true}
			break
		case *uint64:
			flags[fieldName] = FlagParser{(*FlagUInt64)(fieldPtr.(*uint64)), true}
			break

		case **uint:
			flagUInt := FlagUIntNull{fieldPtr.(**uint)}
			flags[fieldName] = FlagParser{flagUInt, true}
			break
		case **uint8:
			flagUInt := FlagUInt8Null{fieldPtr.(**uint8)}
			flags[fieldName] = FlagParser{flagUInt, true}
			break
		case **uint16:
			flagUInt := FlagUInt16Null{fieldPtr.(**uint16)}
			flags[fieldName] = FlagParser{flagUInt, true}
			break
		case **uint32:
			flagUInt := FlagUInt8Null{fieldPtr.(**uint8)}
			flags[fieldName] = FlagParser{flagUInt, true}
			break
		case **uint64:
			flagUInt := FlagUInt64Null{fieldPtr.(**uint64)}
			flags[fieldName] = FlagParser{flagUInt, true}
			break

		case *string:
			flags[fieldName] = FlagParser{(*FlagString)(fieldPtr.(*string)), true}
			break
		case **string:
			flagString := FlagStringNull{fieldPtr.(**string)}
			flags[fieldName] = FlagParser{flagString, true}
			break

		case *bool:
			flags[fieldName] = FlagParser{(*FlagBool)(fieldPtr.(*bool)), false}
			break

		default:
			fieldPtrTyped, ok := fieldPtr.(FlagValue)
			if !ok {
				return nil, fmt.Errorf("type '%v' doesn't implement FlagValue", fieldEntry.Type)
			}
			flags[fieldName] = FlagParser{fieldPtrTyped, true}
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
			flag := arg[1:]
			setter, ok := flagParsers[flag]
			if !ok {
				return fmt.Errorf("flag '%v' not recognized", arg)
			}

			if !setter.RequiresValue {
				err := setter.Value.ParseFlag(flag)
				if err != nil {
					return err
				}
				continue
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

func MutuallyExclusive(arg1, arg2 bool, args ...bool) (int, error) {
	if arg1 && arg2 {
		return -1, fmt.Errorf("got multiple mutually exclusive arguments")
	}

	if arg1 {
		for _, arg := range args {
			if arg {
				return -1, fmt.Errorf("got multiple mutually exclusive arguments")
			}
		}
		return -1, nil
	}

	if arg2 {
		for _, arg := range args {
			if arg {
				return -1, fmt.Errorf("got multiple mutually exclusive arguments")
			}
		}
		return -1, nil
	}

	found := -1
	for idx, arg := range args {

		if arg {
			if found != -1 {
				return -1, fmt.Errorf("got multiple mutually exclusive arguments")
			}
			found = idx
		}
	}
	return found, nil
}

func (s FlagStringNull) ParseFlag(value string) error {
	*s.Value = &value
	return nil
}

func (b *FlagString) ParseFlag(value string) error {
	*b = FlagString(value)
	return nil
}

func (b *FlagUInt) ParseFlag(value string) error {
	i, err := strconv.Atoi(value)
	if err != nil {
		return err
	}

	*b = FlagUInt(i)
	return nil
}

func (b *FlagUInt8) ParseFlag(value string) error {
	i, err := strconv.ParseUint(value, 10, 8)
	if err != nil {
		return err
	}

	*b = FlagUInt8(i)
	return nil
}

func (b *FlagUInt16) ParseFlag(value string) error {
	i, err := strconv.ParseUint(value, 10, 16)
	if err != nil {
		return err
	}

	*b = FlagUInt16(i)
	return nil
}

func (b *FlagUInt32) ParseFlag(value string) error {
	i, err := strconv.ParseUint(value, 10, 32)
	if err != nil {
		return err
	}

	*b = FlagUInt32(i)
	return nil
}

func (b *FlagUInt64) ParseFlag(value string) error {
	i, err := strconv.ParseUint(value, 10, 64)
	if err != nil {
		return err
	}

	*b = FlagUInt64(i)
	return nil
}

func (b FlagUIntNull) ParseFlag(value string) error {
	i, err := strconv.Atoi(value)
	if err != nil {
		return err
	}
	val := uint(i)
	*b.Value = &val
	return nil
}

func (b FlagUInt8Null) ParseFlag(value string) error {
	i, err := strconv.ParseUint(value, 10, 8)
	if err != nil {
		return err
	}
	val := uint8(i)
	*b.Value = &val
	return nil
}

func (b FlagUInt16Null) ParseFlag(value string) error {
	i, err := strconv.ParseUint(value, 10, 16)
	if err != nil {
		return err
	}
	val := uint16(i)
	*b.Value = &val
	return nil
}

func (b FlagUInt32Null) ParseFlag(value string) error {
	i, err := strconv.ParseUint(value, 10, 32)
	if err != nil {
		return err
	}
	val := uint32(i)
	*b.Value = &val
	return nil
}

func (b FlagUInt64Null) ParseFlag(value string) error {
	i, err := strconv.ParseUint(value, 10, 64)
	if err != nil {
		return err
	}
	val := uint64(i)
	*b.Value = &val
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

func (b *FlagInt8) ParseFlag(value string) error {
	i, err := strconv.ParseInt(value, 10, 8)
	if err != nil {
		return err
	}

	*b = FlagInt8(i)
	return nil
}

func (b *FlagInt16) ParseFlag(value string) error {
	i, err := strconv.ParseInt(value, 10, 16)
	if err != nil {
		return err
	}

	*b = FlagInt16(i)
	return nil
}

func (b *FlagInt32) ParseFlag(value string) error {
	i, err := strconv.ParseInt(value, 10, 32)
	if err != nil {
		return err
	}

	*b = FlagInt32(i)
	return nil
}

func (b *FlagInt64) ParseFlag(value string) error {
	i, err := strconv.ParseInt(value, 10, 64)
	if err != nil {
		return err
	}

	*b = FlagInt64(i)
	return nil
}

func (b FlagIntNull) ParseFlag(value string) error {
	i, err := strconv.Atoi(value)
	if err != nil {
		return err
	}

	*b.Value = &i
	return nil
}

func (b FlagInt8Null) ParseFlag(value string) error {
	i, err := strconv.ParseInt(value, 10, 8)
	if err != nil {
		return err
	}
	val := int8(i)
	*b.Value = &val
	return nil
}

func (b FlagInt16Null) ParseFlag(value string) error {
	i, err := strconv.ParseInt(value, 10, 16)
	if err != nil {
		return err
	}
	val := int16(i)
	*b.Value = &val
	return nil
}

func (b FlagInt32Null) ParseFlag(value string) error {
	i, err := strconv.ParseInt(value, 10, 32)
	if err != nil {
		return err
	}
	val := int32(i)
	*b.Value = &val
	return nil
}

func (b FlagInt64Null) ParseFlag(value string) error {
	i, err := strconv.ParseInt(value, 10, 64)
	if err != nil {
		return err
	}
	val := int64(i)
	*b.Value = &val
	return nil
}

func (b *FlagBool) ParseFlag(value string) error {
	*b = FlagBool(true)
	return nil
}
