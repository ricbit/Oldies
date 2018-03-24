graph := {{0, 0, 1}, {1, 0, 0}, {1, 1, 0}}
count[graph_, pos_, size_] := With[{n = Length[graph]},
  SeriesCoefficient[LinearSolve[
      IdentityMatrix[n] - z Transpose[graph],
      ConstantArray[z, n]][[pos]],
    {z, 0, size + 1}]]
Print[Table[count[graph, 1, n], {n, 0, 6}]]

