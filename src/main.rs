/*
Booltable
Takes a boolean expression such as A+B and outputs a truth table for the expression
Should be able to compute expressions such as (A+B).C

How it works
1. Ingest the boolean variables and identify them
2. Come up with a table of all boolean variations that makes up the N variables
3. Build a sytax tree of the expression
4. Evaluate the syntax tree and output the results
5. Print a tabular representation of the values
 */

// Boolean operations
// + -> OR
// . -> AND(Binary)
// ! -> NOT(Unary)

use std::collections::HashMap;
use std::vec::Vec;

struct BoolDict {
    tokens: Vec<char>,
}

impl BoolDict {
    fn add(self: &mut Self, char: char) {
        if char.is_alphanumeric() && !self.tokens.contains(&char) {
            self.tokens.push(char);
        }
    }
}

#[derive(Debug)]
struct Node {
    left: NodeKind,
    operator: char,
    right: NodeKind,
    not: bool,
}

#[derive(Debug)]
enum NodeKind {
    TreeNode(Box<Node>),
    STRING(String),
}

struct TokenStream {
    tokens: String,
}

impl TokenStream {
    fn new(tokens: String) -> Self {
        TokenStream { tokens }
    }

    fn consume(self: &mut Self) -> char {
        if self.tokens.len() > 1 {
            return self.tokens.remove(0);
        }
        self.tokens.clone().as_bytes()[0] as char
    }
}

fn main() {
    let mut store = HashMap::<String, String>::new();
    let sample_expression = String::from("a.b.!(c.d)");
    let dict = lexer(sample_expression.clone());

    build_initial_table(dict.tokens.into_iter().collect::<String>(), &mut store);

    let mut stream = TokenStream::new(sample_expression);
    let expression_tree = parse(&mut stream, &mut 0, &false);
    println!("{:#?}", expression_tree);

    match expression_tree {
        NodeKind::TreeNode(tree_node) => {
            let result = generate_truth(*tree_node, &mut store);
            println!("Result = {}", result);
            for (k, v) in store.iter() {
                println!("{} -> {}", k, v);
            }
        }
        _ => {}
    }
}

fn lexer(expression: String) -> BoolDict {
    let mut bool_dict = BoolDict { tokens: vec![] };

    for char in expression.chars() {
        bool_dict.add(char);
    }

    bool_dict
}

fn build_initial_table(tokens: String, store: &mut HashMap<String, String>) {
    let ceiling = 2_u32.pow(tokens.len() as u32);
    let token_len = tokens.len() as u32;

    for i in 0..ceiling {
        let bin_str = binary_string(i, Some(token_len));
        for (idx, token) in tokens.chars().enumerate() {
            let mut value: String;
            match store.get(&String::from(token)) {
                Some(val) => {
                    value = String::from(val);
                }
                None => {
                    store.insert(String::from(token), String::from(""));
                    value = String::from(store.get(&String::from(token)).unwrap());
                }
            }
            value += &bin_str.get(idx).unwrap().to_string();
            store.insert(String::from(token), value);
        }
    }
}

fn binary_string(n: u32, adjust: Option<u32>) -> Vec<u32> {
    let mut num = n;
    let mut result: Vec<u32> = vec![];

    if n == 0 {
        result.push(0);
    }

    loop {
        if num == 0 {
            break;
        }
        let div = num / 2;
        let remainder = num - (div * 2);
        num = div;
        result.push(remainder);
    }

    match adjust {
        Some(adj) => {
            let mut diff = adj - result.len() as u32;
            loop {
                if diff == 0 {
                    break;
                }
                result.push(0);
                diff -= 1;
            }
        }
        None => {}
    }

    result.reverse();

    result
}

fn parse(stream: &mut TokenStream, braces: &mut u32, not: &bool) -> NodeKind {
    let mut f_not = false;

    let mut left_node = stream.consume();
    
    if left_node == '!' {
        f_not = true;
        left_node = stream.consume();
    }

    let mut left_node_kind: NodeKind = NodeKind::STRING(String::from(String::from(if f_not { "!".to_owned() } else { "".to_owned() } + &String::from(left_node))));

    if left_node == '(' {
        *braces += 1;
        left_node_kind = parse(stream, braces, &f_not);
        left_node = stream.consume();
    }

    if left_node == ')' {
        *braces -= 1;
        return left_node_kind;
    }
    
    let next_token = stream.consume();

    if is_op(next_token) {
        let right_node = parse(stream, braces, not);

        match right_node {
            NodeKind::TreeNode(boxed_node) => {
                return NodeKind::TreeNode(Box::new(Node {
                    left: left_node_kind,
                    operator: next_token,
                    right: NodeKind::TreeNode(boxed_node),
                    not: *not,
                }));
            }
            NodeKind::STRING(string_node) => {
                return NodeKind::TreeNode(Box::new(Node {
                    left: left_node_kind,
                    operator: next_token,
                    right: NodeKind::STRING(string_node),
                    not: *not,
                }));
            }
        }
    }
    left_node_kind
}

fn build_node_str(node: &Node) -> String {
    let mut out = String::from("");
    match &node.left {
        NodeKind::STRING(str) => {
            out += &str;
        }
        NodeKind::TreeNode(sub_node) => {
            out += &build_node_str(&*sub_node);
        }
    }

    out += &String::from(node.operator);

    match &node.right {
        NodeKind::STRING(str) => {
            out += &str;
        }
        NodeKind::TreeNode(sub_node) => {
            out += &build_node_str(&*sub_node);
        }
    }
    out = "(".to_owned() + &out + ")";
    if node.not {
        return "!".to_owned() + &out;
    }
    out
}

fn generate_truth(node: Node, store: &mut HashMap<String, String>) -> String {
    let mut buffer = String::from("");
    let mut a: String;
    let mut b: String;
    match node.left {
        NodeKind::STRING(var) => {
            if var.len() > 1 {
                let var_char = String::from(var.as_bytes()[1] as char);
                let var_value = store.get(&var_char).unwrap();
                let values = evaluate_node(var_value.clone(), '!', var_value.clone(), Some(true));
                store.insert(var.clone(), values);
            }
            buffer += &var;
            a = var;
        }
        NodeKind::TreeNode(sub_node) => {
            let node_str = build_node_str(&sub_node);
            let values = generate_truth(*sub_node, &mut store.clone());
            store.insert(node_str.clone(), values);
            buffer += &node_str;
            a = node_str;
        }
    }
    buffer += &String::from(node.operator);
    match node.right {
        NodeKind::STRING(var) => {
            if var.len() > 1 {
                let var_char = String::from(var.as_bytes()[1] as char);
                let var_value = store.get(&var_char).unwrap();
                let values = evaluate_node(var_value.clone(), '!', var_value.clone(), Some(true));
                store.insert(var.clone(), values);
            }
            buffer += &var;
            b = var;
        }
        NodeKind::TreeNode(sub_node) => {
            let node_str = build_node_str(&sub_node);
            let values = generate_truth(*sub_node, &mut store.clone());
            store.insert(node_str.clone(), values);
            buffer += &node_str;
            b = node_str;
        }
    }
    a = String::from(store.get(&a).unwrap());
    b = String::from(store.get(&b).unwrap());

    let mut result = evaluate_node(a, node.operator, b.clone(), None);
    store.insert(buffer.clone(), result.clone());

    if node.not {
        let buffer_value = store.get(&buffer).unwrap();
        result = evaluate_node(buffer_value.clone(), '!', buffer_value.clone(), Some(true));
    }

    result
}

fn is_op(char: char) -> bool {
    match char {
        '+' => true,
        '.' => true,
        '!' => true,
        _ => false,
    }
}

// takes a node with no children
// computes the truth value and returns it
fn evaluate_node(a: String, operator: char, b: String, not: Option<bool>) -> String {
    let mut result = String::from("");
    let a_bytes = a.as_bytes();
    let b_bytes = b.as_bytes();

    match not {
        Some(_) => {
            for idx in 0..a.len() {
                result += &String::from(compute(a_bytes[idx] as char, b_bytes[idx] as char, '!'));
            }
        }
        None => {
            for idx in 0..a.len() {
                result += &String::from(compute(a_bytes[idx] as char, b_bytes[idx] as char, operator));
            }
        }
    }

    result
}

fn compute(a: char, b: char, operator: char) -> char {
    let _a = if a == '1' { true } else { false };
    let _b = if b == '1' { true } else { false };
    let result = match operator {
        '+' => _a || _b,
        '.' => _a && _b,
        '!' => !_a,
        _ => false,
    };
    if result {
        '1'
    } else {
        '0'
    }
}
