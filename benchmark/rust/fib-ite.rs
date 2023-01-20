fn fibonacci_iterative(n: i64) -> i64 {
 
    let mut x:i64 = 0;
    let mut y:i64 = 0;
    let mut a:i64 = 1;
 
    let mut i:i64 = 1;
 
    while i < n {
 
        x = y;
 
        y = a;
 
        a = x + y;
 
        i = i + 1;
    }
    return a;
}

fn main() {
    println!("{}", fibonacci_iterative(47));
}

