package day5

import "core:os"
import "core:mem"
import "core:fmt"
import "core:slice"
import "core:bytes"
import "shared:lex"

main :: proc() {
    arena: mem.Arena
    mem.arena_init(&arena, make([]byte, 4*1024*1024))
    defer delete(arena.data)
    context.allocator = mem.arena_allocator(&arena)

    ok: bool

    input: []u8
    input, ok = os.read_entire_file("day5/input.txt")
    if !ok {
        fmt.println("Failed to read input")
        return
    }

    seeds: []int
    maps: []Map
    seeds, maps, ok = parse_input(string(input))
    if !ok {
        fmt.println("Failed to parse input")
        return
    }

    step_1(seeds, maps)
    step_2(seeds, maps)
}

Range :: struct {
    dst_start: int,
    src_start: int,
    count: int,
}

Map :: struct {
    from: string,
    to: string,
    ranges: []Range,
}

parse_input :: proc(input: string) -> (seeds: []int, maps: []Map, ok: bool) {
    map_list := make([dynamic]Map)
    seed_list := make([dynamic]int)
    ranges := make([dynamic]Range)

    l: lex.Lexer
    lexer := &l
    lex.init(lexer, input)

    lex.expect_identifier(lexer, "seeds") or_return
    lex.expect(lexer, lex.Colon) or_return

    for lex.peek(lexer, lex.Number) {
        number := lex.expect(lexer, lex.Number) or_return
        append(&seed_list, number.value)
    }

    for !lex.peek(lexer, lex.EOF) {
        clear(&ranges)
        m: Map
        from := lex.expect(lexer, lex.Identifier) or_return
        lex.expect(lexer, lex.Minus) or_return
        lex.expect_identifier(lexer, "to") or_return
        lex.expect(lexer, lex.Minus) or_return
        to := lex.expect(lexer, lex.Identifier) or_return
        lex.expect_identifier(lexer, "map") or_return
        lex.expect(lexer, lex.Colon) or_return

        m.from = from.value
        m.to = to.value

        for lex.peek(lexer, lex.Number) {
            dst_start := lex.expect(lexer, lex.Number) or_return
            src_start := lex.expect(lexer, lex.Number) or_return
            count := lex.expect(lexer, lex.Number) or_return

            append(&ranges, Range{
                dst_start = dst_start.value,
                src_start = src_start.value,
                count = count.value,
            })
        }

        m.ranges = slice.clone(ranges[:])

        append(&map_list, m)
    }

    seeds = slice.clone(seed_list[:])
    maps = slice.clone(map_list[:])
    ok = true
    return
}

step_1 :: proc(seeds: []int, maps: []Map) {
    lowest_location: Maybe(int)

    for seed in seeds {
        number := seed

        state := "seed"
        for m in maps {
            assert(state == m.from)

            for range in m.ranges {
                if number >= range.src_start && number < range.src_start + range.count {
                    number = range.dst_start + (number - range.src_start)
                    break
                }
            }

            state = m.to
        }

        assert(state == "location")

        if lowest_location == nil || number < lowest_location.(int) {
            lowest_location = number
        }
    }


    fmt.println("The lowest location number of the starting seeds is:", lowest_location)
}

step_2 :: proc(seeds: []int, maps: []Map) {
    lowest_location: Maybe(int)

    // sort ranges and fill gaps
    ranges := make([dynamic]Range)
    for &m in maps {
        slice.sort_by(m.ranges, proc(i, j: Range) -> bool {
            return i.src_start < j.src_start
        })

        end := 0

        clear(&ranges)
        for range in m.ranges {
            if (range.src_start > end) {
                append(&ranges, Range{ src_start = end, dst_start = end, count = range.src_start - end })
            }

            append(&ranges, range)
            end = range.src_start + range.count
        }

        append(&ranges, Range { src_start = end, dst_start = end, count = -1 })

        m.ranges = slice.clone(ranges[:])
    }

    // recursively map subranges for each seed
    for i in 0 ..< len(seeds) / 2 {
        vrange_start := seeds[i * 2 + 0]
        vrange_len := seeds[i * 2 + 1]

        process_mapping_recursive(vrange_start, vrange_len, maps, 0, &lowest_location)
    }

    process_mapping_recursive :: proc(vrange_start: int, vrange_len: int,
        maps: []Map, map_index: int, lowest_location: ^Maybe(int)) {

        vrange_start := vrange_start
        vrange_len := vrange_len

        if map_index >= len(maps) {
            if lowest_location^ == nil || vrange_start < lowest_location^.(int) {
                lowest_location^ = vrange_start
            }

            return
        }

        m := maps[map_index]

        // find the range we start in
        range_index := -1
        for i in 0 ..< len(m.ranges) {
            range := m.ranges[i]
            if vrange_start >= range.src_start &&
                (range.count == -1 || vrange_start < range.src_start + range.count) {
                range_index = i
                break
            }
        }

        assert(range_index != -1)

        // process subranges of our value range
        for vrange_len > 0 {
            range := m.ranges[range_index]
            subrange_count := vrange_len
            if range.count != -1 {
                subrange_count = min(vrange_len, (range.src_start + range.count) - vrange_start)
            }

            process_mapping_recursive(range.dst_start + (vrange_start - range.src_start), subrange_count, maps, map_index + 1, lowest_location)

            vrange_start += subrange_count
            vrange_len -= subrange_count
            range_index += 1
        }
    }

    fmt.println("The lowest location number of the corrected starting seeds is:", lowest_location)
}
