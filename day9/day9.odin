package day9

import "core:os"
import "core:mem"
import "core:fmt"
import "core:slice"
import "core:bytes"
import "core:strings"
import "core:strconv"

main :: proc() {
    arena: mem.Arena
    mem.arena_init(&arena, make([]byte, 4*1024*1024))
    defer delete(arena.data)
    context.allocator = mem.arena_allocator(&arena)

    ok: bool

    input: []u8
    input, ok = os.read_entire_file("day9/input.txt")
    if !ok {
        fmt.println("Failed to read input")
        return
    }

    readings: []Reading
    readings, ok = parse_input(string(input))
    if !ok {
        fmt.println("Failed to parse input")
        return
    }

    step_1(readings)
    step_2(readings)
}

Reading :: struct {
    values: []int,
}

parse_input :: proc(input: string) -> (readings: []Reading, ok: bool) {
    readings_list := make([dynamic]Reading)
    value_list := make([dynamic]int)

    input := input
    for line in strings.split_lines_iterator(&input) {
        if len(line) == 0 {
            continue
        }

        clear(&value_list)
        line := line
        for value_string in strings.split_iterator(&line, " ") {
            value := strconv.parse_int(value_string) or_return
            append(&value_list, value)
        }

        reading: Reading
        reading.values = slice.clone(value_list[:])

        append(&readings_list, reading)
    }

    readings = slice.clone(readings_list[:])

    ok = true
    return
}

step_1 :: proc(readings: []Reading) {
    sum := 0
    stack := make([dynamic][]int)

    for reading in readings {
        clear(&stack)

        values := reading.values
        for {
            append_elem(&stack, values)

            all_zero := true
            for value in values {
                if value != 0 {
                    all_zero = false
                    break
                }
            }

            if all_zero {
                break
            }

            diffs := make([]int, len(values) - 1)
            for i in 0 ..< len(diffs) {
                diffs[i] = values[i + 1] - values[i]
            }

            values = diffs
        }

        predicted_value := 0
        #reverse for diffs in stack {
            predicted_value += diffs[len(diffs) - 1]
        }

        sum += predicted_value
    }

    fmt.println("The sum of all predicted values at the end is:", sum)
}

step_2 :: proc(readings: []Reading) {
    sum := 0
    stack := make([dynamic][]int)

    for reading in readings {
        clear(&stack)

        values := reading.values
        for {
            append_elem(&stack, values)

            all_zero := true
            for value in values {
                if value != 0 {
                    all_zero = false
                    break
                }
            }

            if all_zero {
                break
            }

            diffs := make([]int, len(values) - 1)
            for i in 0 ..< len(diffs) {
                diffs[i] = values[i + 1] - values[i]
            }

            values = diffs
        }

        predicted_value := 0
        #reverse for diffs in stack {
            predicted_value = diffs[0] - predicted_value
        }

        sum += predicted_value
    }

    fmt.println("The sum of all predicted values at the beginning is:", sum)
}
