#include <bits/stdc++.h>
using namespace std;
typedef int64_t i64;
enum piece_t { vert = 1, horz };
typedef tuple<i64, i64, i64> board_t;

set<board_t> boards;

void print(const int N, const board_t& b) {
  array<i64, 3> ns {get<0>(b), get<1>(b), get<2>(b)};
  for (int j = 0; j < 3; j++) {
    int n = ns[j];
    for (int i = 0; i <= 2 * N - 1; i += 2) {
      int p = static_cast<int>(n >> i) & 3;
      if (p == vert) {
        cout << 'v';
      } else {
        cout << (p == horz ? 'h' : '.');
      }
    }
    cout << '\n';
  }
}

board_t set_ver_piece_at(const board_t& b, int row, int col) {
  if (col < 0 || row < 0) return b;
  array<i64, 3> ns {get<0>(b), get<1>(b), get<2>(b)};
  int mask = vert << (2 * (col - 1));
  ns[row] |= mask;
  ns[row + 1] |= mask;
  return {ns[0], ns[1], ns[2]};
}

board_t set_hor_piece_at(const board_t& b, int row, int col) {
  if (col < 0) return b;
  array<i64, 3> ns {get<0>(b), get<1>(b), get<2>(b)};
  ns[row] |= (10 << (2 * (col  - 2)));
  return {ns[0], ns[1], ns[2]};
}

bool is_ver_free(const int row, const int col, const board_t& b) {
  array<i64, 3> ns{get<0>(b), get<1>(b), get<2>(b)};
  int c = col - 1;
  i64 n1 = ns[row] & (3 << (2 * c));
  i64 n2 = ns[row + 1] & (3 << (2 * c));
  return !n1 && !n2;
}

bool is_hor_free(const int row, const int col, const board_t& b) {
  if (col < 2) return false;
  array<i64, 3> ns{get<0>(b), get<1>(b), get<2>(b)};
  i64 n = ns[row];
  return !(n & (15 << (2 * (col - 2))));
}

void find_all(int n0, int n1, int n2, const board_t& b) {
  if (n0 < 0 || n1 < 0 || n2 < 0) return;
  if (!n0 && !n1 && !n2 && !boards.count(b)) {
    boards.insert(b);
    return;
  }
  if (is_hor_free(0, n0, b))
    find_all(n0 - 2, n1, n2, set_hor_piece_at(b, 0, n0));
  if (is_hor_free(1, n1, b))
    find_all(n0, n1 - 2, n2, set_hor_piece_at(b, 1, n1));
  if (is_hor_free(2, n2, b))
    find_all(n0, n1, n2 - 2, set_hor_piece_at(b, 2, n2));

  if (is_ver_free(0, n0, b))
    find_all(n0 - 1, n1 - 1, n2, set_ver_piece_at(b, 0, n0));
  if (is_ver_free(1, n1, b))
    find_all(n0, n1 - 1, n2 - 1, set_ver_piece_at(b, 1, n1));
}

int main() {
  int n;
  cin >> n;
  find_all(n, n, n, {0, 0, 0});
  cout << "total boards: " << boards.size() << '\n';
  string _; getline(cin, _, '\n');
  for (const board_t& b : boards) {
    print(n, b);
    cout << '\n';
  }
  return 0;
}
