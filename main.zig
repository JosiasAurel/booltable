// Booltable
// A tool that takes in an expression such as A+B
// and outputs a truth table
// should also be able to compute expressions such as (A+B).C
// and more complex ones (obviously)

// How it works
// 1. Identify the boolean variables
// 2. Come up with a table of all the boolean variations that the N variables make up
// 3. Build an AST of the expression
// 4. Evaluate the AST and give out the result
// *5. Determine the steps required to go from bool var definition to final expression
// *6. Print a tabular/any form of representation of that

// Boolean operations
// + -> or (binary)
// . -> and (binary)
// ! -> not (unary)

const std = @import("std");
const print = std.debug.print;
const BoundedArray = std.BoundedArray;
const ConvBoundedArray = BoundedArray(u8, 40);

pub fn main() !void {
    const result = simple_lexer("abcde");
    for (result.tokens()) |char| {
        print("Got token {c}\n", .{char});
    }

    var r0 = try base_10_to_binary(0);
    var r1 = try base_10_to_binary(1);
    var r2 = try base_10_to_binary(2);
    var r3 = try base_10_to_binary(3);
    var r4 = try base_10_to_binary(4);
    var r7 = try base_10_to_binary(7);

    print("0 = {s}\n", .{r0.constSlice()});
    print("1 = {s}\n", .{r1.constSlice()});
    print("2 = {s}\n", .{r2.constSlice()});
    print("3 = {s}\n", .{r3.constSlice()});
    print("4 = {s}\n", .{r4.constSlice()});
    print("7 = {s}\n", .{r7.constSlice()});

    var a_r7 = try adjust(8, r7.constSlice());
    print("7 = {s}\n", .{a_r7.constSlice()});
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

fn base_10_to_binary(num: u32) !ConvBoundedArray {
    var future_result = try ConvBoundedArray.init(20);
    // if (num == 0) return "0";
    var result: [20]u8 = undefined;
    var idx: usize = 0;

    // so lazy mehn
    if (num == 0) {
        future_result.set(0, '0');
        try future_result.resize(1);
        return future_result;
    }

    var _num = num;
    // print("Converting {}\n", .{num});
    while (_num != 0) {
        var rem = @rem(_num, 2);
        // print("rem = {}\n", .{rem});
        _num = @divFloor(_num, 2);
        future_result.set(idx, @intCast(rem + 48));
        // try future_result.append(@intCast(rem + 48));
        result[idx] = @intCast(rem + 48);
        idx += 1;
    }

    try future_result.resize(idx);

    // reverse the string
    for (0..idx - 1) |i| {
        var _temp = future_result.get(i);
        future_result.set(i, future_result.get(idx - i - 1));
        future_result.set(idx - i - 1, _temp);
        var temp = result[i];
        result[i] = result[idx - i - 1];
        result[idx - i - 1] = temp;
    }
    return future_result;
}

// adds the missing zeros
// before a binary string
// to match the number of unique variables
// in a boolean expression
fn adjust(var_len: usize, str: []const u8) !ConvBoundedArray {
    var future_buffer = try ConvBoundedArray.init(20);
    var missing_zero_count = var_len - str.len;
    var buffer: [50]u8 = undefined;
    var idx: usize = 0;

    for (0..missing_zero_count) |_| {
        future_buffer.set(idx, '0');
        buffer[idx] = '0';
        idx += 1;
    }
    for (str) |char| {
        future_buffer.set(idx, char);
        buffer[idx] = char;
        idx += 1;
    }

    try future_buffer.resize(idx);
    return future_buffer;
}

// Evaluating these boolean operations
// for N unique variables, we will have (2^N - 1) states for the combinations
//
