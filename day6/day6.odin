package day6

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
    input, ok = os.read_entire_file("day6/input.txt")
    if !ok {
        fmt.println("Failed to read input")
        return
    }

    races: []Race
    races, ok = parse_input(string(input))
    if !ok {
        fmt.println("Failed to parse input")
        return
    }

    step_1(races)
    step_2(races)
}

Race :: struct {
    duration: int,
    record: int,
}

parse_input :: proc(input: string) -> (races: []Race, ok: bool) {
    race_list := make([dynamic]Race)

    l: lex.Lexer
    lexer := &l
    lex.init(lexer, input)

    lex.expect_identifier(lexer, "Time") or_return
    lex.expect(lexer, lex.Colon) or_return

    for lex.peek(lexer, lex.Number) {
        number := lex.expect(lexer, lex.Number) or_return
        append(&race_list, Race{ duration = number.value })
    }

    lex.expect_identifier(lexer, "Distance") or_return
    lex.expect(lexer, lex.Colon) or_return

    for &race in race_list {
        number := lex.expect(lexer, lex.Number) or_return
        race.record = number.value
    }

    lex.expect(lexer, lex.EOF) or_return

    races = slice.clone(race_list[:])
    ok = true
    return
}

step_1 :: proc(races: []Race) {
    result := 1

    for race in races {
        ways_to_beat := 0
        for charge_duration in 0 ..= race.duration {
            velocity := 1 * charge_duration
            distance := velocity * (race.duration - charge_duration)
            if distance > race.record {
                ways_to_beat += 1
            }
        }

        result *= ways_to_beat
    }

    fmt.println("The product of all ways to beat the races is:", result)
}

step_2 :: proc(races: []Race) {
    duration := 0
    record := 0
    for race in races {
        factor := 1
        for race.duration >= factor {
            factor *= 10
        }

        duration = duration * factor + race.duration

        factor = 1
        for race.record >= factor {
            factor *= 10
        }

        record = record * factor + race.record
    }

    ways_to_beat := 0
    for charge_duration in 0 ..= duration {
        velocity := 1 * charge_duration
        distance := velocity * (duration - charge_duration)
        if distance > record {
            ways_to_beat += 1
        }
    }

    fmt.println("The number of ways to beat the correct race is:", ways_to_beat)
}
