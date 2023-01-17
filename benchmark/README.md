## Apple M1

This is benchmark suite inlcuding the test results for Apple M1 architecture. 

|  | fibonacci-recursive | fibonacci-interative | matrix |
|------:|:------:|:------:|:------:|
| NodeJS 19.4.0 |  0m17.014s | 0m0.045s |  |
| | 37MB | 37MB |  |
| Lua | 0m8.707s |  |  |
| | 1.6MB | 1.6MB |  |
| LuaJIT | 0m7.908s |  |  |
| | 37MB | | |
| Perl 5.36.0 | 10m52.958s | 0m0.021s |  |
| | 3MB | 3MB |  |
| Python 3.11.1 | 5m26.112s | 0m0.055s |  |
| | 9MB | 9MB |  |
| Rust 1.61.1 | 0m23.777s |  |  |

|  | fib-rec | fib-int | matrix |
|------:|:------:|:------:|:------:| 
| NodeJS 19.4.0 |  37MB  | 37MB |  |
| Lua | yes | | |
| LuaJIT | yes |  | |
| Perl 5.36.0 | 2.2MB | 2MB |  |
| Python 3.11.1 | 9MB | 8MB |  |
| Rust 1.61.1 |  |  |  |


### Benchmark suite
#### fibonacci-recursive: Fibonacci Recursive method calculate 47th element
#### fib-ite: Fibonacci Iterative method
#### matrix: Matrix multiplication

### Software
- NodeJS: 19.4.0 https://nodejs.org/en/
- Lua: Kronometrix Data Recording https://gitlab.com/kronometrix/recording
- LuaJIT: Kronometrix Data Recording https://gitlab.com/kronometrix/recording
- Perl: 5.36.0 Kronometrix Data Recording https://gitlab.com/kronometrix/recording
- Python: 3.11.1 Official distribution https://www.python.org/downloads/
- Rust: 1.61.1 https://www.rust-lang.org

