## Apple M1

This is benchmark suite inlcuding the test results for Apple M1 architecture. 

|  | fib-rec | fib-int | matrix |
|------:|:------:|:------:|:------:| 
| NodeJS 19.4.0 |  00:27s  | 00:00.11s |  |
|  | 37MB | 37MB | |
| Lua | yes | | |
|  | 37MB | 37MB |  |
| LuaJIT | yes |  | |
|  | 37MB | 37MB |  |
| Perl 5.36.0 | 10:50s |  |  |
|  | 2MB | |  |
| Python 3.11.1 | 05:33s | 0:00.03s |  |
|  | 9MB | 9MB |  |
| Rust 1.61.1 |  |  |  |

### Benchmark suite
#### fib-rec: Fibonacci Recursive method
#### fib-ite: Fibonacci Iterative method
#### matrix: Matrix multiplication

### Software
- NodeJS: 19.4.0 https://nodejs.org/en/
- Lua: Kronometrix Data Recording https://gitlab.com/kronometrix/recording
- LuaJIT: Kronometrix Data Recording https://gitlab.com/kronometrix/recording
- Perl: 5.36.0 Kronometrix Data Recording https://gitlab.com/kronometrix/recording
- Python: 3.11.1 Official distribution https://www.python.org/downloads/
- Rust: 1.61.1 https://www.rust-lang.org

