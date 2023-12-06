package day4

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
    input, ok = os.read_entire_file("day4/input.txt")
    if !ok {
        fmt.println("Failed to read input")
        return
    }

    cards: []Scratch_Card
    cards, ok = parse_cards(string(input))
    if !ok {
        fmt.println("Failed to parse cards")
        return
    }

    step_1(cards)
    step_2(cards)
}

Scratch_Card :: struct {
    card_number: int,
    winning_numbers: []int,
    numbers: []int,
}

parse_cards :: proc(input: string) -> (result: []Scratch_Card, ok: bool) {
    cards := make([dynamic]Scratch_Card)

    l: lex.Lexer
    lexer := &l
    lex.init(lexer, input)

    numbers := make([dynamic]int)

    for !lex.peek(lexer, lex.EOF) {
        card: Scratch_Card
        lex.expect_identifier(lexer, "Card") or_return

        number := lex.expect(lexer, lex.Number) or_return
        card.card_number = number.value

        lex.expect(lexer, lex.Colon) or_return

        clear(&numbers)
        for lex.peek(lexer, lex.Number) {
            number = lex.expect(lexer, lex.Number) or_return
            append(&numbers, number.value)
        }

        card.winning_numbers = slice.clone(numbers[:])

        lex.expect(lexer, lex.Pipe) or_return

        clear(&numbers)
        for lex.peek(lexer, lex.Number) {
            number = lex.expect(lexer, lex.Number) or_return
            append(&numbers, number.value)
        }

        card.numbers = slice.clone(numbers[:])

        append(&cards, card)
    }

    result = slice.clone(cards[:])
    ok = true
    return
}

step_1 :: proc(cards: []Scratch_Card) {
    sum := 0

    for card in cards {
        point_value := 0
        for number in card.numbers {
            if slice.contains(card.winning_numbers, number) {
                point_value = 1 if point_value == 0 else point_value * 2
            }
        }

        sum += point_value
    }

    fmt.println("The sum of points is:", sum)
}

step_2 :: proc(cards: []Scratch_Card) {
    card_count := make([]int, len(cards))
    slice.fill(card_count, 1)

    for i in 0 ..< len(cards) {
        card := cards[i]
        count := card_count[i]

        num_matches := 0
        for number in card.numbers {
            if slice.contains(card.winning_numbers, number) {
                num_matches += 1
            }
        }

        for j in 0 ..< num_matches {
            card_count[card.card_number + j] += count
        }
    }

    sum := 0
    for count in card_count {
        sum += count
    }

    fmt.println("The total number of cards is:", sum)
}
