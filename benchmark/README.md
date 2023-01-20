## Results

Check the results of the benchmark test suite on different computer systems. Includes Apple M1/M2, X64 FreeBSD and Raspberry PI computers. 

<table>
  <tr> 
    <th colspan="5">Apple M1</th> 
  </tr> 
  <tr>
    <th></td>
    <th>Fibonacci-Rec</th>
    <th>Fibonacci-Iterative</th>
    <th>Matrix</th>
    <th>Description</th>
  </tr>
  <tr>
    <td align="center"; colspan="5">Total elapsed time, Memory usage</td>
  </tr>
  
  <tr> 
    <th>NodeJS</th> 
    <td>0m17.014s, 37MB</td> 
    <td>0m0.045s, 37MB</td> 
    <td></td>
    <td>19.4.0 Release</td>
  </tr> 
  
  <tr> 
    <th>Lua</th> 
    <td>0m8.707s, 1.6MB</td> 
    <td>0m0.007s, 1.6MB</td> 
    <td></td>
    <td></td>
  </tr>

  <tr> 
    <th>LuaJIT</th> 
    <td>0m7.908s, 1.3MB</td> 
    <td>0m0.005s, 1.3MB</td> 
    <td></td>
    <td></td>
  </tr>

  <tr> 
    <th>Perl</th> 
    <td>10m52.958s, 3MB</td> 
    <td>0m0.021s, 3MB</td> 
    <td></td>
    <td></td>
  </tr>

  <tr> 
    <th>Python</th> 
    <td>5m26.112s, 9MB</td> 
    <td>0m0.055s, 9MB</td> 
    <td></td>
    <td></td>
  </tr> 

  <tr> 
    <th>Rust</th> 
    <td>0m23.414s, 1MB</td> 
    <td>0m0.006s, 1MB</td> 
    <td></td>
    <td></td>
  </tr> 

  <tr>
    <td align="left"; colspan="5">The system was connected to mains power during benchmark. Running MacOS 13.1</td>
  </tr>


</table>


### Benchmark suite
#### FibRec(47): calculate fibonacci(50) recursive way
#### FibIterative(47): calculate fibonacci(50) iterative way
#### Matrix: perform matrix multiplication

### Software
- NodeJS: 19.4.0 https://nodejs.org/en/
- Lua: Kronometrix Data Recording https://gitlab.com/kronometrix/recording
- LuaJIT: Kronometrix Data Recording https://gitlab.com/kronometrix/recording
- Perl: 5.36.0 Kronometrix Data Recording https://gitlab.com/kronometrix/recording
- Python: 3.11.1 Official distribution https://www.python.org/downloads/
- Rust: 1.61.1 https://www.rust-lang.org

