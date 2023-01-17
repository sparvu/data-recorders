let fib_iterative = function (n) {
   let sequenceArray = [0, 1];
   for (var i = 2; i <= n; i++) {
      sequenceArray.push(sequenceArray[i-1] + sequenceArray[i-2]);
   }
   return sequenceArray;
}

console.log(fib_iterative(47));
