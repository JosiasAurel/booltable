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
const StringHashMap = std.StringHashMap;
var HeapAllocator = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = HeapAllocator.allocator();
const ExpressionStore = StringHashMap(ConvBoundedArray);
var store = ExpressionStore.init(allocator);

pub fn main() !void {
    const result = simple_lexer("a+b");

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

    const sample = "a+b";
    const tokens = simple_lexer(sample);
    print("sample = {s} & tokens = {s}\n", .{ sample, tokens.tokens() });
    try set_initial_variables(tokens.tokens());
    print("Reading a = {s} \n", .{store.get("a").?.constSlice()});
    var ast = try parse(sample);
    print_ast(ast);

    const check = HeapAllocator.deinit();
    switch (check) {
        .leak => {
            print("Memory leak after deinit\n", .{});
        },
        .ok => {},
    }
}

fn print_ast(ast: AstNodeKind) void {
    switch (ast) {
        .uniq => print("uniq => {c}\n", .{ast.uniq}),
        .node => {
            print_ast(ast.node.left);
            print("op -> {c}\n", .{ast.node.operator});
            print_ast(ast.node.right);
        },
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
        return self.store[0..self.idx];
    }
    fn len(self: Self) usize {
        return self.idx;
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
fn adjust(var_count: usize, str: []const u8) !ConvBoundedArray {
    var future_buffer = try ConvBoundedArray.init(20);
    var missing_zero_count = var_count - str.len;
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

const TokenStream = struct {
    const Self = @This();
    tokens: []const u8,
    idx: usize = 0,

    fn consume(self: *Self) u8 {
        const result = self.tokens[self.idx];
        self.idx += 1;
        return result;
    }
};

// this step should involve constructing the table
// of the boolean expression
// so as we encounter an expression, we should build

const AstNode = struct { left: AstNodeKind, operator: u8, right: AstNodeKind };
const AstNodeKind = union(enum) { uniq: u8, node: *AstNode };

fn parse(expression: []const u8) !AstNodeKind {
    if (expression.len == 1) return AstNodeKind{ .uniq = expression[0] };

    var tokens = TokenStream{ .tokens = expression };

    const left_node = tokens.consume();
    const next_token = tokens.consume();
    if (is_op(next_token)) {
        const right_node = try parse(expression[tokens.idx..expression.len]);

        switch (right_node) {
            .uniq => {
                const buffer = [3]u8{ left_node, next_token, right_node.uniq };
                print("buffer = {s}\n", .{buffer});
                if (!store.contains(&buffer)) {
                    try gen_and_put_truth(buffer);
                }
                // return AstNodeKind{ .node = &AstNode{ .left = AstNodeKind{ .uniq = left_node }, .operator = next_token, .right = @constCast(AstNodeKind{ .uniq = right_node.uniq }) } };
            },

            .node => {
                // return AstNodeKind{ .node = &AstNode{ .left = AstNodeKind{ .node = left_node }, .operator = next_token, .right = AstNodeKind{ .node = right_node } } };
            },
        }

        // ast node
    }

    return AstNodeKind{ .uniq = left_node };
}

fn gen_and_put_truth(str: [3]u8) !void {
    var res = store.get("a").?;
    print(" x = {s}", .{res.constSlice()});
    print(" x = {?}", .{store.get(&[1]u8{str[0]})});
    const x = store.get(&[1]u8{str[0]}).?.constSlice();
    const y = store.get(&[1]u8{str[2]}).?.constSlice();
    var buffer = try ConvBoundedArray.init(20);
    var idx: usize = 0;

    switch (str[1]) {
        '+' => {
            for (x, 0..x.len) |b, i| {
                buffer.set(idx, b | y[i]);
            }
        },
        '.' => {
            for (x, 0..x.len) |b, i| {
                buffer.set(idx, b & y[i]);
            }
        },
        '!' => {},
        else => {},
    }

    try buffer.resize(8);
    try store.put(&str, buffer);
}

fn is_op(tok: u8) bool {
    return switch (tok) {
        '+', '!', '.' => true,
        else => false,
    };
}

fn char_to_num(char: u8) u32 {
    return @intCast(char - 48);
}

fn set_initial_variables(variables: []const u8) !void {
    print("working {s} & len = {}\n", .{ variables, variables.len });

    // store the variables in a bounded array to avoid use after free
    var vars = try ConvBoundedArray.init(5);
    for (variables, 0..variables.len) |c, i| {
        vars.set(i, c);
    }
    try vars.resize(variables.len);

    // get the max decimal number to be attained while calculating
    var max = pow(2, @intCast(variables.len));

    // a buffer to store the binary string
    var buffer = try ConvBoundedArray.init(20);
    for (variables, 0..variables.len) |c, i| {
        _ = c;
        var idx: usize = 0;
        for (0..max) |item| {
            const bin_str = try adjust(variables.len, (try base_10_to_binary(@intCast(item))).constSlice());
            buffer.set(idx, bin_str.get(i));
            idx += 1;
        }
        try buffer.resize(max);

        // please make an ugly fuckery here till it works
        var s: [1]u8 = undefined;
        s[0] = vars.get(i);
        try store.put([1]u8{vars.get(i)}, buffer);
    }
}

fn pow(base: u32, exp: u32) u32 {
    var result = base;
    for (0..exp - 1) |_| {
        result *= base;
    }
    return result;
}

// Evaluating these boolean operations
// for N unique variables, we will have (2^N - 1) states for the combinations
//
