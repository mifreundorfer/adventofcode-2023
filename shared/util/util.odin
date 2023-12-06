package util

is_digit :: proc(c: u8) -> bool {
    return c >= '0' && c <= '9'
}