package day3

import "core:os"
import "core:mem"
import "core:fmt"
import "core:slice"
import "core:bytes"
import "shared:util"

main :: proc() {
    arena: mem.Arena
    mem.arena_init(&arena, make([]byte, 4*1024*1024))
    defer delete(arena.data)
    context.allocator = mem.arena_allocator(&arena)

    ok: bool

    input: []u8
    input, ok = os.read_entire_file("day3/input.txt")
    if !ok {
        fmt.println("Failed to read input")
        return
    }

    schematic: Schematic
    schematic, ok = parse_schematic(input)
    if !ok {
        fmt.println("Failed to parse schematic")
        return
    }

    step_1(schematic)
    step_2(schematic)
}

Part_Number :: struct {
    value: int,
    y: int,
    x_min: int,
    x_max: int,
}

Schematic :: struct {
    width: int,
    height: int,
    data: [][]u8,
    part_numbers: []Part_Number,
}

parse_schematic :: proc(input: []u8) -> (schematic: Schematic, ok: bool) {
    first_line := true

    lines := make([dynamic][]u8)

    line_start := 0
    i: int
    for i = 0; i < len(input); i +=1 {
        if input[i] == '\n' {
            line_length := i - line_start
            if first_line {
                schematic.width = line_length
                first_line = false
            } else if schematic.width != line_length  {
                fmt.printf("Line length mismatch, expected %v, got %v\n", schematic.width, line_length)
                return
            }

            append(&lines, input[line_start:i])
            line_start = i + 1
        }
    }

    // assume a trailing newline
    assert(i == line_start)

    schematic.height = len(lines)
    schematic.data = slice.clone(lines[:])

    part_numbers := make([dynamic]Part_Number)

    for y in 0 ..< schematic.height {
        line := schematic.data[y]
        number := 0
        for x := 0; x < schematic.width; x += 1 {
            if util.is_digit(line[x]) {
                number := 0
                x_start := x
                for ; x < schematic.width && util.is_digit(line[x]); x += 1 {
                    number = number * 10 + int(line[x] - '0')
                }

                append(&part_numbers, Part_Number {
                    value = number,
                    y = y,
                    x_min = x_start,
                    x_max = x - 1,
                })
            }
        }
    }

    schematic.part_numbers = slice.clone(part_numbers[:])

    ok = true
    return
}

step_1 :: proc(schematic: Schematic) {
    sum := 0

    outer:
    for part_number in schematic.part_numbers {
        x_min := max(0, part_number.x_min - 1)
        x_max := min(schematic.width - 1, part_number.x_max + 1)
        y_min := max(0, part_number.y - 1)
        y_max := min(schematic.height - 1, part_number.y + 1)

        for y := y_min; y <= y_max; y += 1 {
            line := schematic.data[y]
            for x := x_min; x <= x_max; x += 1 {
                if !(util.is_digit(line[x]) || line[x] == '.') {
                    sum += part_number.value
                    continue outer
                }
            }
        }
    }

    fmt.println("The sum of all part numbers next to symbols is:", sum)
}

step_2 :: proc(schematic: Schematic) {
    sum := 0

    for y in 0 ..< schematic.height {
        line := schematic.data[y]
        for x in 0 ..< schematic.width {
            if line[x] == '*' {

                ratio := 1
                num_parts := 0
                for part_number in schematic.part_numbers {
                    if (part_number.y >= y - 1 && part_number.y <= y + 1
                        && part_number.x_max >= x - 1 && part_number.x_min <= x + 1) {
                        ratio *= part_number.value
                        num_parts += 1
                    }
                }

                if num_parts == 2 {
                    sum += ratio
                }
            }
        }
    }

    fmt.println("The sum of all the gear ratios is:", sum)
}
