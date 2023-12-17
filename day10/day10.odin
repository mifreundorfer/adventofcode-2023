package day10

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
    input, ok = os.read_entire_file("day10/input.txt")
    if !ok {
        fmt.println("Failed to read input")
        return
    }

    pipes: Pipes
    pipes, ok = parse_input(string(input))
    if !ok {
        fmt.println("Failed to parse input")
        return
    }

    step_1(pipes)
    step_2(pipes)
}

Cell :: enum {
    Ground,
    Start,
    NS,
    EW,
    NE,
    ES,
    SW,
    WN,
}

Direction :: enum {
    North,
    East,
    South,
    West
}

Pipes :: struct {
    cells: []Cell,
    width: int,
    height: int,
    start_x: int,
    start_y: int,
}

Cell_Direction :: struct {
    cell: Cell,
    dir1: Direction,
    dir2: Direction,
}

cell_directions := []Cell_Direction {
    { .NS, .North, .South },
    { .EW, .East, .West },
    { .NE, .North, .East },
    { .ES, .East, .South },
    { .SW, .South, .West },
    { .WN, .West, .North },
}

parse_input :: proc(input: string) -> (pipes: Pipes, ok: bool) {
    lines := strings.split_lines(input)

    pipes.width = len(lines[0])
    pipes.height = len(lines) - 1
    pipes.cells = make([]Cell, pipes.width * pipes.height)

    for y in 0 ..< pipes.height {
        line := lines[y]
        assert(len(line) == pipes.width)
        for x in 0 ..< pipes.width {
            cell: Cell
            switch line[x] {
                case '.': cell = .Ground
                case '|': cell = .NS
                case '-': cell = .EW
                case 'L': cell = .NE
                case 'F': cell = .ES
                case '7': cell = .SW
                case 'J': cell = .WN
                case 'S': cell = .Start
                case: return
            }

            if (cell == .Start) {
                pipes.start_x = x
                pipes.start_y = y
            }

            pipes.cells[x + y * pipes.width] = cell
        }
    }

    ok = true
    return
}

step_1 :: proc(pipes: Pipes) {
    x := pipes.start_x
    y := pipes.start_y
    dir: Direction

    cell := pipes.cells[(x - 1) + y * pipes.width]
    if cell == .EW || cell == .ES || cell == .NE {
        dir = .West
    }

    cell = pipes.cells[(x + 1) + y * pipes.width]
    if cell == .EW || cell == .SW || cell == .WN {
        dir = .East
    }

    cell = pipes.cells[x + (y - 1) * pipes.width]
    if cell == .NS || cell == .ES || cell == .SW {
        dir = .North
    }

    cell = pipes.cells[x + (y + 1) * pipes.width]
    if cell == .NS || cell == .NE || cell == .WN {
        dir = .South
    }

    loop_length := 0
    for {
        loop_length += 1

        if dir == .North {
            y -= 1
            cell = pipes.cells[x + y * pipes.width]
            if cell == .Start {
                break
            } else if cell == .NS {
                dir = .North
            } else if cell == .ES {
                dir = .East
            } else if cell == .SW {
                dir = .West
            } else {
                assert(false, "Invalid connection")
            }
        } else if dir == .East {
            x += 1
            cell = pipes.cells[x + y * pipes.width]
            if cell == .Start {
                break
            } else if cell == .EW {
                dir = .East
            } else if cell == .SW {
                dir = .South
            } else if cell == .WN {
                dir = .North
            } else {
                assert(false, "Invalid connection")
            }
        } else if dir == .South {
            y += 1
            cell = pipes.cells[x + y * pipes.width]
            if cell == .Start {
                break
            } else if cell == .NS {
                dir = .South
            } else if cell == .NE {
                dir = .East
            } else if cell == .WN {
                dir = .West
            } else {
                assert(false, "Invalid connection")
            }
        } else if dir == .West {
            x -= 1
            cell = pipes.cells[x + y * pipes.width]
            if cell == .Start {
                break
            } else if cell == .EW {
                dir = .West
            } else if cell == .ES {
                dir = .South
            } else if cell == .NE {
                dir = .North
            } else {
                assert(false, "Invalid connection")
            }
        }
    }

    fmt.println("The amount of steps to the farthest position from the start is:", loop_length / 2)
}

step_2 :: proc(pipes: Pipes) {
    tags := make([]bool, len(pipes.cells))

    x := pipes.start_x
    y := pipes.start_y
    start_dirs := make([dynamic]Direction)

    cell := pipes.cells[(x - 1) + y * pipes.width]
    if cell == .EW || cell == .ES || cell == .NE {
        append(&start_dirs, Direction.West)
    }

    cell = pipes.cells[(x + 1) + y * pipes.width]
    if cell == .EW || cell == .SW || cell == .WN {
        append(&start_dirs, Direction.East)
    }

    cell = pipes.cells[x + (y - 1) * pipes.width]
    if cell == .NS || cell == .ES || cell == .SW {
        append(&start_dirs, Direction.North)
    }

    cell = pipes.cells[x + (y + 1) * pipes.width]
    if cell == .NS || cell == .NE || cell == .WN {
        append(&start_dirs, Direction.South)
    }

    assert(len(start_dirs) == 2)
    dir := start_dirs[0]

    // Tag all cells that belong to the pipe loop
    for {
        tags[x + y * pipes.width] = true

        if dir == .North {
            y -= 1
            cell = pipes.cells[x + y * pipes.width]
            if cell == .Start {
                break
            } else if cell == .NS {
                dir = .North
            } else if cell == .ES {
                dir = .East
            } else if cell == .SW {
                dir = .West
            } else {
                assert(false, "Invalid connection")
            }
        } else if dir == .East {
            x += 1
            cell = pipes.cells[x + y * pipes.width]
            if cell == .Start {
                break
            } else if cell == .EW {
                dir = .East
            } else if cell == .SW {
                dir = .South
            } else if cell == .WN {
                dir = .North
            } else {
                assert(false, "Invalid connection")
            }
        } else if dir == .South {
            y += 1
            cell = pipes.cells[x + y * pipes.width]
            if cell == .Start {
                break
            } else if cell == .NS {
                dir = .South
            } else if cell == .NE {
                dir = .East
            } else if cell == .WN {
                dir = .West
            } else {
                assert(false, "Invalid connection")
            }
        } else if dir == .West {
            x -= 1
            cell = pipes.cells[x + y * pipes.width]
            if cell == .Start {
                break
            } else if cell == .EW {
                dir = .West
            } else if cell == .ES {
                dir = .South
            } else if cell == .NE {
                dir = .North
            } else {
                assert(false, "Invalid connection")
            }
        }
    }

    // Fix up the start cell direction
    for cell_direction in cell_directions {
        if ((start_dirs[0] == cell_direction.dir1 && start_dirs[1] == cell_direction.dir2)
         || (start_dirs[1] == cell_direction.dir1 && start_dirs[0] == cell_direction.dir2)) {
            pipes.cells[pipes.start_x + pipes.start_y * pipes.width] = cell_direction.cell
            break
        }
    }

    // Count the number of intersections with the pipe loop.
    // An even amount of intersections means the cell is outside of the loop polygon
    sum := 0
    for y in 0 ..< pipes.height {
        for x in 0 ..< pipes.width {
            if tags[x + y * pipes.width] {
                continue
            }

            // An intersections only happens when the pipe crosses the horizontal axis.
            // Pipes going from east to west only intersect when the exit directions are
            // different. Otherwise the pipe turns back and the "ray" only went along the edge.
            num_intersections := 0
            intersection_in: Maybe(Direction)
            for x1 in x + 1 ..< pipes.width {
                is_pipe := tags[x1 + y * pipes.width]
                cell := pipes.cells[x1 + y * pipes.width]
                if is_pipe {
                    if intersection_in == nil {
                        if cell == .NS {
                            num_intersections += 1
                        } else if cell == .EW {
                            assert(false, "Should not be possible")
                        } else if cell == .NE || cell == .WN {
                            intersection_in = .North
                        } else if cell == .ES || cell == .SW {
                            intersection_in = .South
                        } else {
                            assert(false, "Unhandled case")
                        }
                    } else {
                        if cell == .NS {
                            assert(false, "Should not be possible")
                        } else if cell == .EW {
                            // continue the current intersection
                        } else if cell == .NE || cell == .WN {
                            if intersection_in == .South {
                                num_intersections += 1
                            }

                            intersection_in = nil
                        } else if cell == .ES || cell == .SW {
                            if intersection_in == .North {
                                num_intersections += 1
                            }

                            intersection_in = nil
                        } else {
                            assert(false, "Unhandled case")
                        }
                    }
                } else {
                    assert(intersection_in == nil)
                }
            }

            if num_intersections % 2 == 1 {
                sum += 1
            }
        }
    }

    fmt.println("The number of cells enclosed by the loop is:", sum)
}
