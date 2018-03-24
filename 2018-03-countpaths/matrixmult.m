graph := {{0, 0, 1}, {1, 0, 0}, {1, 1, 0}}
count[graph_, pos_, size_] :=
  Total[MatrixPower[graph, size] . UnitVector[Length[graph], pos]]
Print[Table[count[graph, 1, n], {n, 0, 6}]]

