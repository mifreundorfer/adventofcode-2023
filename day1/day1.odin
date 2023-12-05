package day1

import "core:os"
import "core:mem"
import "core:fmt"
import "core:unicode"

main :: proc() {
    arena: mem.Arena
    mem.arena_init(&arena, make([]byte, 4*1024*1024))
    defer delete(arena.data)
    context.allocator = mem.arena_allocator(&arena)

    input, ok := os.read_entire_file("day1/input.txt")
    if !ok {
        fmt.println("Failed to read input")
        return
    }

    step_1(string(input))
    step_2(string(input))
}

step_1 :: proc(input: string) {
    sum := 0

    first_digit: Maybe(rune)
    last_digit: Maybe(rune)
    for c in input {
        if c == '\n' {
            sum += int(first_digit.(rune) - '0') * 10 + int(last_digit.(rune) - '0')
            first_digit = nil
            last_digit = nil
            continue
        }

        if unicode.is_digit(c) {
            if (first_digit == nil) {
                first_digit = c
            }

            last_digit = c
        }
    }

    fmt.println("The sum of all calibration values is:", sum)
}

Digit :: struct {
    key: string,
    value: int,
}

digits := []Digit {
    { "1", 1 },
    { "2", 2 },
    { "3", 3 },
    { "4", 4 },
    { "5", 5 },
    { "6", 6 },
    { "7", 7 },
    { "8", 8 },
    { "9", 9 },
    { "one",   1 },
    { "two",   2 },
    { "three", 3 },
    { "four",  4 },
    { "five",  5 },
    { "six",   6 },
    { "seven", 7 },
    { "eight", 8 },
    { "nine",  9 },
}

step_2 :: proc(input: string) {
    sum := 0

    first_digit: Maybe(int)
    last_digit: Maybe(int)
    i := 0
    for i < len(input) {
        c := input[i]
        if c == '\n' {
            sum += first_digit.(int) * 10 + last_digit.(int)
            first_digit = nil
            last_digit = nil
            i += 1
            continue
        }

        for digit in digits {
            if i + len(digit.key) <= len(input) && input[i:i+len(digit.key)] == digit.key {
                if (first_digit == nil) {
                    first_digit = digit.value
                }

                last_digit = digit.value
                break
            }
        }

        i += 1
    }

    fmt.println("The corrected sum of all calibration values is:", sum)
}