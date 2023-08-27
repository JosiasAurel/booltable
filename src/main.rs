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
    right: NodeKind
}

#[derive(Debug)]
enum NodeKind {
    TreeNode(Box<Node>),
    STRING(String)
}

struct TokenStream {
    tokens: String,
}

impl TokenStream {
    fn new(tokens: String) -> Self {
        TokenStream {
            tokens,
        }
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
    let sample_expression = String::from("a+b+c");
    let dict = lexer(sample_expression.clone());

    build_initial_table(dict.tokens.into_iter().collect::<String>(), &mut store);

    let expression_tree = parse(sample_expression);
    println!("{:?}", expression_tree);
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

fn parse(expression: String) -> NodeKind {
    let mut stream = TokenStream::new(expression);

    let left_node = stream.consume();
    let next_token = stream.consume();

    if is_op(next_token) {
        let right_node = parse(stream.tokens);

        match right_node {
            NodeKind::TreeNode(boxed_node) => {
                println!("got here once");
               return NodeKind::TreeNode(Box::new(Node {
                left: NodeKind::STRING(String::from(left_node)),
                operator: next_token,
                right: NodeKind::TreeNode(boxed_node)
               }));
            },
            NodeKind::STRING(string_node) => {
                return NodeKind::TreeNode(Box::new(Node {
                    left: NodeKind::STRING(String::from(left_node)),
                    operator: next_token,
                    right: NodeKind::STRING(string_node) 
                }));
            }
        }
    }
    NodeKind::STRING(String::from(left_node))
}

fn is_op(char: char) -> bool {
    match char {
        '+' => true,
        '.' => true,
        '!' => true,
        _ => false
    }
}