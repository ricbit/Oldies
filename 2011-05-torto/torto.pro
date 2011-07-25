% Torto Reverso
% Ricardo Bittencourt 2011 

valid(I,J) :-
  between(0, 2, I),
  between(0, 5, J).

move(I, J, left, X, J) :-
  X is I - 1,
  valid(X, J).

move(I, J, right, X, J) :-
  X is I + 1,
  valid(X, J).

move(I, J, up, I, Y) :-
  Y is J - 1,
  valid(I, Y).

move(I, J, down, I, Y) :-
  Y is J + 1,
  valid(I, Y).

move(I, J, up_left, X, Y) :-
  X is I - 1,
  Y is J - 1,
  valid(X, Y).

move(I, J, down_left, X, Y) :-
  X is I - 1,
  Y is J + 1,
  valid(X, Y).

move(I, J, up_right, X, Y) :-
  X is I + 1,
  Y is J - 1,
  valid(X, Y).

move(I, J, down_right, X, Y) :-
  X is I + 1,
  Y is J + 1,
  valid(X, Y).

validBlock(X, _, X, _, Block, Block) :- !.
validBlock(_, Y, _, Y, Block, Block) :- !.
validBlock(X, Y, I, J, OldBlock, NewBlock) :-
  Bx is min(X, I),
  By is min(Y, J),
  \+ member(pos(Bx, By), OldBlock),
  NewBlock = [pos(Bx, By) | OldBlock].

validgrid(Grid) :-
  length(Grid, 18).

validletter(Grid, Letter, X, Y) :-
  valid(X, Y),
  Pos is X + Y * 3,
  nth0(Pos, Grid, Letter).

word(Grid, [Letter], Visited, _, X, Y) :-
  validletter(Grid, Letter, X, Y),
  \+ member(pos(X, Y), Visited).

word(Grid, [Letter | Tail], Visited, Block, X, Y) :-
  validletter(Grid, Letter, X, Y),
  move(X, Y, _, I, J),
  \+ member(pos(X, Y), Visited),
  validBlock(X, Y, I, J, Block, NewBlock),
  word(Grid, Tail, [pos(X, Y) | Visited], NewBlock, I, J).

convert(Ascii, Printable) :-
  number(Ascii) -> 
    Printable = Ascii;
    Printable = '.'.

convertlist([], []).
convertlist([A | B], [C | D]) :-
  convert(A, C),
  convertlist(B, D).

writelist(List) :-
  convertlist(List, Printable),
  writef('%s\n', [Printable]).

writegrid([]).
writegrid([A | [B | [C | Tail]]]) :-
  writelist([A,B,C]),
  writegrid(Tail).

wordlist(_, []).
wordlist(Grid, [Word | WordList]) :-
  word(Grid, Word, [], [], _, _),
  wordlist(Grid, WordList).

solve(WordList) :-
  validgrid(Grid),
  wordlist(Grid, WordList),
  writegrid(Grid).

