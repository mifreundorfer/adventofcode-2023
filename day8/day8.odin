package day8

import "core:os"
import "core:mem"
import "core:fmt"
import "core:slice"
import "core:bytes"
import "core:math"
import "shared:lex"

main :: proc() {
    arena: mem.Arena
    mem.arena_init(&arena, make([]byte, 4*1024*1024))
    defer delete(arena.data)
    context.allocator = mem.arena_allocator(&arena)

    ok: bool

    input: []u8
    input, ok = os.read_entire_file("day8/input.txt")
    if !ok {
        fmt.println("Failed to read input")
        return
    }

    m: Map
    m, ok = parse_input(string(input))
    if !ok {
        fmt.println("Failed to parse input")
        return
    }

    step_1(m)
    step_2(m)
}

Instruction :: enum {
    Left,
    Right,
}

Node :: struct {
    id: string,
    left: string,
    right: string,
}

Map :: struct {
    nodes: map[string]Node,
    instructions: []Instruction,
}

parse_input :: proc(input: string) -> (m: Map, ok: bool) {
    l: lex.Lexer
    lexer := &l
    lex.init(lexer, input)

    identifier := lex.expect(lexer, lex.Identifier) or_return
    instruction_string := identifier.value

    m.instructions = make([]Instruction, len(instruction_string))
    for i in 0 ..< len(instruction_string) {
        m.instructions[i] = .Left if instruction_string[i] == 'L' else .Right
    }

    for !lex.peek(lexer, lex.EOF) {
        node: Node
        identifier = lex.expect(lexer, lex.Identifier) or_return
        node.id = identifier.value

        lex.expect(lexer, lex.Equals) or_return
        lex.expect(lexer, lex.LeftBrace) or_return
        identifier = lex.expect(lexer, lex.Identifier) or_return
        node.left = identifier.value
        lex.expect(lexer, lex.Comma) or_return
        identifier = lex.expect(lexer, lex.Identifier) or_return
        node.right = identifier.value
        lex.expect(lexer, lex.RightBrace) or_return

        m.nodes[node.id] = node
    }


    ok = true
    return
}

step_1 :: proc(m: Map) {
    num_steps := 0

    current := "AAA"
    instruction_index := 0

    for current != "ZZZ" {
        node := m.nodes[current]
        instruction := m.instructions[instruction_index]

        current = node.left if instruction == .Left else node.right
        num_steps += 1

        instruction_index += 1
        if instruction_index >= len(m.instructions) {
            instruction_index = 0
        }
    }

    fmt.println("The amount of steps to reach ZZZ is:", num_steps)
}

State :: struct {
    start: string,
    loop_step_count: u64,
}

step_2 :: proc(m: Map) {
    // Select all beginning states
    states := make([dynamic]State)
    for id in m.nodes {
        if id[2] == 'A' {
            append(&states, State{id, 0})
        }
    }

    // Find the step count to reach the target state
    for &state in states {
        current := state.start
        instruction_index := 0
        step_count := u64(0)
        end: Maybe(string) = nil

        for {
            step_count += 1
            instruction := m.instructions[instruction_index]
            node := m.nodes[current]
            current = node.left if instruction == .Left else node.right

            instruction_index += 1
            if instruction_index >= len(m.instructions) {
                instruction_index = 0
            }

            if current[2] == 'Z' {
                if end == nil {
                    assert(instruction_index == 0)
                    end = current
                    state.loop_step_count = step_count
                } else {
                    assert(current == end)
                    assert(instruction_index == 0)
                    assert(step_count == 2 * state.loop_step_count)
                    break
                }
            }
        }
    }

    // Calculate lcm of all loop counts
    lcm := math.lcm(states[0].loop_step_count, states[1].loop_step_count)
    for state in states[2:] {
        lcm = math.lcm(state.loop_step_count, lcm)
    }

    fmt.println("The amount of steps to reach all nodes ending with Z simultaniously is:", lcm)
}
