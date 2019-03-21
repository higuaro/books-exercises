#include <bits/stdc++.h>
using namespace std;
typedef int64_t i64;
enum piece_t { vert = 1, horz };
typedef tuple<i64, i64, i64> board_t;
int N;

set<board_t> boards;
set<tuple<i64, i64, i64, board_t>> memo;

board_t set_ver_piece_at(const board_t& b, int row, int col) {
  if (col < 1 || row < 1) return b;
  int c = col - 1;
  int r = row - 1;
  array<i64, 3> ns {get<0>(b), get<1>(b), get<2>(b)};
  int mask = vert << (2 * c);
  ns[r] |= mask;
  ns[r + 1] |= mask;
  return {ns[0], ns[1], ns[2]};
}

board_t set_hor_piece_at(const board_t& b, int row, int col) {
  if (col < 2 || row < 1) return b;
  int c = col - 1;
  int r = row - 1;
  array<i64, 3> ns {get<0>(b), get<1>(b), get<2>(b)};
  ns[r] |= (10 << (2 * (c - 1)));
  return {ns[0], ns[1], ns[2]};
}

bool is_ver_free(const int row, const int col, const board_t& b) {
  if (!row || !col) return false;
  int r = row - 1;
  int c = col - 1;
  array<i64, 3> ns{get<0>(b), get<1>(b), get<2>(b)};

  i64 n1 = ns[r] & (3 << (2 * c));
  i64 n2 = ns[r + 1] & (3 << (2 * c));
  return !n1 && !n2;
}

bool is_hor_free(const int row, const int col, const board_t& b) {
  if (col < 2) return false;
  if (!row || !col) return false;
  int r = row - 1;
  int c = col - 1;
  array<i64, 3> ns{get<0>(b), get<1>(b), get<2>(b)};

  i64 n = ns[r];
  return !(n & (15 << (2 * (c - 1))));
}

int find_all(int n1, int n2, int n3, const board_t& b) {
  tuple<i64, i64, i64, board_t> t = make_tuple(n1, n2, n3, b);
  if (memo.count(t)) return 0;

  if (n1 < 0 || n2 < 0 || n3 < 0) return 0;
  if (!n1 && !n2 && !n3 && !boards.count(b)) {
    boards.insert(b);
    return 1;
  }

  int total = 0;
  if (is_hor_free(1, n1, b))
    total += find_all(n1 - 2, n2, n3, set_hor_piece_at(b, 1, n1));
  if (is_hor_free(2, n2, b))
    total += find_all(n1, n2 - 2, n3, set_hor_piece_at(b, 2, n2));
  if (is_hor_free(3, n3, b))
    total += find_all(n1, n2, n3 - 2, set_hor_piece_at(b, 3, n3));

  if (is_ver_free(1, n1, b))
    total += find_all(n1 - 1, n2 - 1, n3, set_ver_piece_at(b, 1, n1));
  if (is_ver_free(2, n2, b))
    total += find_all(n1, n2 - 1, n3 - 1, set_ver_piece_at(b, 2, n2));

  memo.insert(t);
  return total;
}
int main() {
  int n; cin >> n;
  N = n;
  cout << find_all(n, n, n, {0, 0, 0}) << '\n';
  return 0;
}
