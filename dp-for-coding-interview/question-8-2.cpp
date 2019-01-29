#include <bits/stdc++.h>
using namespace std;
typedef int64_t i64;
typedef tuple<i64, i64, i64> board_t;
set<board_t> boards_found;
int solve_d(int n1, int n2, int n3, const string& tab = "") {
  clog << tab << '(' << n1 << ',' << n2 << ',' << n3 << ')';
  if (n1 < 0 || n2 < 0 || n3 < 0) {
    clog << " X" << endl;
    return 0;
  }
  if (!n1 && !n2 && !n3) {
    clog << " v/ +1" << endl;
    return 1;
  }

  clog << endl;

  string t = tab + "--";
  int r1 = solve_d(n1 - 1, n2 - 1, n3    , t);
  int r2 = solve_d(n1,     n2 - 1, n3 - 1, t);

  int r3 = solve_d(n1 - 2, n2    , n3    , t);
  int r4 = solve_d(n1    , n2 - 2, n3    , t);
  int r5 = solve_d(n1    , n2    , n3 - 2, t);

  return r1 + r2 + r3 + r4 + r5;
}
board_t new_board(const board_t& board, int row, int col) {
  if (row < 0 || col < 0) return board;
  auto [r1, r2, r3] = board;
  i64 r;
  switch (row) {
    case 0: r = r1; break;
    case 1: r = r2; break;
    case 2: r = r3; break;
  }
  r |= (3 << col);
  switch (row) {
    case 0:  return {r , r2, r3};
    case 1:  return {r1, r , r3};
    default: return {r1, r2, r };
  }
}

int solve(int n1, int n2, int n3, board_t board) {
  if (n1 < 0 || n2 < 0 || n3 < 0) return 0;
  if (!n1 && !n2 && !n3 && !boards_found.count(board)) {
    boards_found.insert(board);
    return 1;
  }

  int r1 = solve(n1 - 1, n2 - 1, n3    , board);
  int r2 = solve(n1,     n2 - 1, n3 - 1, board);

  int r3 = solve(n1 - 2, n2    , n3    , new_board(board, 0, n1 - 2));
  int r4 = solve(n1    , n2 - 2, n3    , new_board(board, 1, n2 - 2));
  int r5 = solve(n1    , n2    , n3 - 2, new_board(board, 2, n3 - 2));

  return r1 + r2 + r3 + r4 + r5;
}
int main() {
  size_t n; // cin >> n;
  n = 2;
  assert(n < 64);
  cout << solve(n, n, n, {0, 0, 0}) << '\n';
  return 0;
}
