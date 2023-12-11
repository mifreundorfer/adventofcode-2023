package day6

import "core:os"
import "core:mem"
import "core:fmt"
import "core:slice"
import "core:bytes"
import "core:strings"

main :: proc() {
    arena: mem.Arena
    mem.arena_init(&arena, make([]byte, 4*1024*1024))
    defer delete(arena.data)
    context.allocator = mem.arena_allocator(&arena)

    ok: bool

    input: []u8
    input, ok = os.read_entire_file("day7/input.txt")
    if !ok {
        fmt.println("Failed to read input")
        return
    }

    hands: []Hand
    hands, ok = parse_input(string(input))
    if !ok {
        fmt.println("Failed to parse input")
        return
    }

    step_1(hands)
    step_2(hands)
}

Card :: enum {
    Two = 2,
    Three = 3,
    Four = 4,
    Five = 5,
    Six = 6,
    Seven = 7,
    Eight = 8,
    Nine = 9,
    Ten = 10,
    Jack = 11,
    Queen = 12,
    King = 13,
    Ace = 14,
}

Hand_Type :: enum {
    High_Card = 1,
    One_Pair = 2,
    Two_Pairs = 3,
    Three_Of_A_Kind = 4,
    Full_House = 5,
    Four_Of_A_Kind = 6,
    Five_Of_A_Kind = 7,
}

Hand :: struct {
    cards: [5]Card,
    bid: int,
}

Card_Set :: struct {
    card: Card,
    count: int,
}

parse_input :: proc(input: string) -> (hands: []Hand, ok: bool) {
    hand_list := make([dynamic]Hand)

    str := input
    for line in strings.split_lines_iterator(&str) {
        if len(line) == 0 {
            continue
        }

        hand: Hand

        for i in 0 ..<5 {
            switch line[i] {
                case '2': hand.cards[i] = Card.Two
                case '3': hand.cards[i] = Card.Three
                case '4': hand.cards[i] = Card.Four
                case '5': hand.cards[i] = Card.Five
                case '6': hand.cards[i] = Card.Six
                case '7': hand.cards[i] = Card.Seven
                case '8': hand.cards[i] = Card.Eight
                case '9': hand.cards[i] = Card.Nine
                case 'T': hand.cards[i] = Card.Ten
                case 'J': hand.cards[i] = Card.Jack
                case 'Q': hand.cards[i] = Card.Queen
                case 'K': hand.cards[i] = Card.King
                case 'A': hand.cards[i] = Card.Ace
                case: assert(false)
            }
        }

        assert(line[5] == ' ')

        for i in 6 ..<len(line) {
            hand.bid = hand.bid * 10 + int(line[i] - '0')
        }

        append(&hand_list, hand)
    }

    hands = slice.clone(hand_list[:])
    ok = true
    return
}

step_1 :: proc(hands: []Hand) {
    classify_hand :: proc(hand: Hand) -> Hand_Type {
        sets: [5]Card_Set
        num_sets := 0

        outer:
        for card in hand.cards {
            for &set in sets[0:num_sets] {
                if set.card == card {
                    set.count += 1
                    continue outer
                }
            }

            sets[num_sets].card = card
            sets[num_sets].count = 1
            num_sets += 1
        }

        for set in sets[0:num_sets] {
            if set.count == 5 {
                return .Five_Of_A_Kind
            }

            if set.count == 4 {
                return .Four_Of_A_Kind
            }

            if set.count == 3 {
                return .Full_House if num_sets == 2 else .Three_Of_A_Kind
            }

            if set.count == 2 && num_sets > 2 {
                return .Two_Pairs if num_sets == 3 else .One_Pair
            }
        }

        return .High_Card
    }

    slice.sort_by(hands, proc(a, b: Hand) -> bool {
        type_a := classify_hand(a)
        type_b := classify_hand(b)

        if type_a != type_b {
            return type_a < type_b
        }

        for i in 0 ..< 5 {
            if a.cards[i] != b.cards[i] {
                return a.cards[i] < b.cards[i]
            }
        }

        return false
    })

    sum := 0
    for hand, i in hands {
        sum += (i + 1) * hand.bid
    }

    fmt.println("The sum of all winnings is:", sum)
}

step_2 :: proc(hands: []Hand) {
    classify_hand :: proc(hand: Hand) -> Hand_Type {
        sets: [5]Card_Set
        num_sets := 0

        joker_count := 0

        outer:
        for card in hand.cards {
            if card == .Jack {
                joker_count += 1
            }

            for &set in sets[0:num_sets] {
                if set.card == card {
                    set.count += 1
                    continue outer
                }
            }

            sets[num_sets].card = card
            sets[num_sets].count = 1
            num_sets += 1
        }

        has_joker := joker_count > 0

        if num_sets == 1 {
            // JJJJJ or 11111
            return .Five_Of_A_Kind
        }

        if num_sets == 2 {
            // JJ11, JJJ11 or 11122
            if has_joker {
                return .Five_Of_A_Kind
            }

            return .Four_Of_A_Kind if sets[0].count == 4 || sets[1].count == 4 else .Full_House
        }

        if num_sets == 3 {
            has_triple := false
            for set in sets[0:num_sets] {
                if set.count == 3 {
                    has_triple = true
                }
            }

            if has_triple {
                // JJJ12, J1112 or 11123
                return .Four_Of_A_Kind if has_joker else .Three_Of_A_Kind
            } else if has_joker {
                // JJ112 or J1122
                return .Four_Of_A_Kind if joker_count == 2 else .Full_House
            } else {
                // 11223
                return .Two_Pairs
            }
        }

        if num_sets == 4 {
            // JJ123, J1123 or 11234
            return .Three_Of_A_Kind if has_joker else .One_Pair
        }

        // J1235 or 12345
        return .One_Pair if has_joker else .High_Card
    }

    slice.sort_by(hands, proc(a, b: Hand) -> bool {
        type_a := classify_hand(a)
        type_b := classify_hand(b)

        if type_a != type_b {
            return type_a < type_b
        }

        for i in 0 ..< 5 {
            value_a := 1 if a.cards[i] == .Jack else int(a.cards[i])
            value_b := 1 if b.cards[i] == .Jack else int(b.cards[i])
            if value_a != value_b {
                return value_a < value_b
            }
        }

        return false
    })

    sum := 0
    for hand, i in hands {
        sum += (i + 1) * hand.bid
    }

    fmt.println("The sum of all winnings with jokers is:", sum)
}
