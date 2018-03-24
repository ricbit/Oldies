graph := {{0, 0, 1}, {1, 0, 0}, {1, 1, 0}}
count[graph_, pos_, 0] := 1
count[graph_, pos_, size_] := Sum[
    If[graph[[i, pos]] == 1, count[graph, i, size - 1], 0],
    {i, 1, Length[graph]}]
Print[Table[count[graph, 1, n], {n, 0, 6}]]

