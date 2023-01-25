import java.util.*;

public class fibrec {
  static long fib(long n) {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
  }

  public static void main(String[] args) {
    System.out.print(fib(47));
  }
}
