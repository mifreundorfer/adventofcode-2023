package lex

import "core:unicode"
import "core:unicode/utf8"
import "core:fmt"

Lexer :: struct {
    text: string,
    at: int,
    current: rune,
    advance: int,
    token: Token,
}

Newline :: struct {}
Colon :: struct {}
Comma :: struct {}
Semicolon :: struct {}
EOF :: struct {}
Number :: struct {
    value: int,
}
Identifier :: struct {
    value : string
}

Token :: union {
    EOF,
    Newline,
    Colon,
    Comma,
    Semicolon,
    Number,
    Identifier,
}

init :: proc(lexer: ^Lexer, text: string) {
    lexer.text = text
    lexer.at = 0
    decode_next_rune(lexer)
    next(lexer)
}

next :: proc(lexer: ^Lexer) -> Token {
    result := lexer.token

    skip_whitespace(lexer)

    if (lexer.current == utf8.RUNE_EOF) {
        lexer.token = EOF{}
    } else if is_digit(lexer.current) {
        number := 0
        for is_digit(lexer.current) {
            number = number * 10 + int(lexer.current - '0')
            decode_next_rune(lexer)
        }

        lexer.token = Number{number}
    } else if unicode.is_alpha(lexer.current) {
        start := lexer.at
        for unicode.is_alpha(lexer.current) {
            decode_next_rune(lexer)
        }

        lexer.token = Identifier{lexer.text[start:lexer.at]}
    } else if lexer.current == ';' {
        decode_next_rune(lexer)
        lexer.token = Semicolon{}
    } else if lexer.current == ':' {
        decode_next_rune(lexer)
        lexer.token = Colon{}
    } else if lexer.current == ',' {
        decode_next_rune(lexer)
        lexer.token = Comma{}
    } else {
        decode_next_rune(lexer)
        lexer.token = nil
    }

    return result
}

is_eof :: proc(token: Token) -> bool {
    _, ok := token.(EOF)
    return ok
}

expect_identifier :: proc(lexer: ^Lexer, value: string) -> (Identifier, bool) {
    result, ok := lexer.token.(Identifier)
    if !ok || result.value != value {
        fmt.printf("Expected Identifier '%v' \n", value)
        return {}, false
    }

    next(lexer)
    return result, true
}

expect :: proc(lexer: ^Lexer, $T: typeid) -> (T, bool) {
    result, ok := lexer.token.(T)
    if !ok {
        fmt.printf("Expected %v \n", typeid_of(T))
        return {}, false
    }

    next(lexer)
    return result, true
}

peek :: proc(lexer: ^Lexer, $T: typeid) -> bool {
    _, ok := lexer.token.(T)
    return ok
}

is_digit :: proc(r: rune) -> bool {
    return r >= '0' && r <= '9'
}

decode_next_rune :: proc(lexer: ^Lexer) -> rune {
    lexer.at += lexer.advance
    if lexer.at >= len(lexer.text) {
        lexer.current = utf8.RUNE_EOF
        lexer.advance = 0
    } else {
        lexer.current, lexer.advance = utf8.decode_rune(lexer.text[lexer.at:])
    }

    return lexer.current
}

skip_whitespace :: proc(lexer: ^Lexer) {
    for unicode.is_white_space(lexer.current) {
        decode_next_rune(lexer)
    }
}