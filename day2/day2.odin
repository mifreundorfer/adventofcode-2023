package day2

import "core:os"
import "core:mem"
import "core:fmt"
import "core:slice"
import "shared:lex"

main :: proc() {
    arena: mem.Arena
    mem.arena_init(&arena, make([]byte, 4*1024*1024))
    defer delete(arena.data)
    context.allocator = mem.arena_allocator(&arena)

    ok: bool

    input: []u8
    input, ok = os.read_entire_file("day2/input.txt")
    if !ok {
        fmt.println("Failed to read input")
        return
    }

    games: []Game
    games, ok = parse_games(string(input))
    if !ok {
        fmt.println("Failed to parse games")
        return
    }

    step_1(games)
    step_2(games)
}

Game :: struct {
    id: int,
    rounds: []Round,
}

Round :: struct {
    num_red: int,
    num_green: int,
    num_blue: int,
}

parse_games :: proc(input: string) -> (result: []Game, ok: bool) {
    games := make([dynamic]Game)
    rounds := make([dynamic]Round)

    l: lex.Lexer
    lex.init(&l, input)
    lexer := &l

    for !lex.peek(lexer, lex.EOF) {
        game: Game

        lex.expect_identifier(lexer, "Game") or_return

        number := lex.expect(lexer, lex.Number) or_return
        game.id = number.value

        lex.expect(lexer, lex.Colon) or_return

        clear_dynamic_array(&rounds)
        for lex.peek(lexer, lex.Number) {
            round := parse_round(lexer) or_return
            append(&rounds, round)

            if !lex.peek(lexer, lex.Semicolon) {
                break
            }

            lex.expect(lexer, lex.Semicolon) or_return
        }

        game.rounds = slice.clone(rounds[:])
        append(&games, game)
    }

    result = slice.clone(games[:])
    ok = true
    return
}

parse_round :: proc(lexer: ^lex.Lexer) -> (round: Round, ok: bool) {
    for {
        count := lex.expect(lexer, lex.Number) or_return
        color := lex.expect(lexer, lex.Identifier) or_return

        switch color.value {
            case "red": round.num_red = count.value
            case "green": round.num_green = count.value
            case "blue": round.num_blue = count.value
            case: {
                fmt.printf("Invalid color '%'", color.value)
                return
            }
        }

        if !lex.peek(lexer, lex.Comma) {
            break
        }

        lex.expect(lexer, lex.Comma) or_return
    }

    ok = true
    return
}

step_1 :: proc(games: []Game) {
    sum := 0

    limit_red := 12
    limit_green := 13
    limit_blue := 14

    for game in games {
        valid := true
        for round in game.rounds {
            if (round.num_red > limit_red
                || round.num_green > limit_green
                || round.num_blue > limit_blue) {
                valid = false
                break
            }
        }

        if valid {
            sum += game.id
        }
    }

    fmt.println("The sum of the ids of valid games is:", sum)
}

step_2 :: proc(games: []Game) {
    sum := 0

    for game in games {
        required_red := 0
        required_green := 0
        required_blue := 0

        for round in game.rounds {
            required_red = max(required_red, round.num_red)
            required_green = max(required_green, round.num_green)
            required_blue = max(required_blue, round.num_blue)
        }

        sum += required_red * required_green * required_blue
    }

    fmt.println("The sum of the powers of sets is:", sum)
}
