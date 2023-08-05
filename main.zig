// Booltable
// A tool that takes in an expression such as A+B
// and outputs a truth table
// should also be able to compute expressions such as (A+B).C
// and more complex ones (obviously)

// How it works
// 1. Identify the boolean variables
// 2. Build an AST of the expression
// 3. Evaluate the AST and give out the result
// *4. Determine the steps required to go from bool var definition to final expression
// *5. Print a tabular/any form of representation of that

const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const result = simple_lexer("abcde");
    for (result.tokens()) |char| {
        print("Got token {c}\n", .{char});
    }
}

const BoolDict = struct {
    const Self = @This();
    store: [100]u8 = undefined,
    idx: usize = 0,

    fn add(self: *Self, item: u8) void {
        self.store[self.idx] = item;
        self.idx += 1;
    }

    fn get(self: Self, idx: usize) u8 {
        return self.store[idx];
        // should throw an error
        // if idx > self.idx
    }

    fn exists(self: Self, item: u8) bool {
        for (self.store) |char| {
            if (char == item) {
                return true;
            }
        }
        return false;
    }

    fn tokens(self: Self) []const u8 {
        return self.store[0 .. self.idx - 1];
    }
};

// iterate over the expression string
// return the unique boolean variables in the expression
//
fn simple_lexer(expression: []const u8) BoolDict {
    var dict = BoolDict{};
    for (expression) |char| {
        if (is_alphanumeric(char) and !dict.exists(char)) {
            dict.add(char);
        }
    }

    return dict;
}

// checks for whether a character is a letter (upper/lower-case)
// checkout https://www.cs.cmu.edu/~pattis/15-1XX/common/handouts/ascii.html
fn is_alphanumeric(char: u8) bool {
    if ((char >= 65 and char <= 90) or (char >= 97 and char <= 122)) {
        return true;
    }
    return false;
}
