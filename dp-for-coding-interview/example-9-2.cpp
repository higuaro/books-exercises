#include <bits/stdc++.h>
using namespace std;
const int N = 1e3;
array<array<int, N>, N> memo;
int solve(int r, int c, int R, int C) {
  if (r >= R || c >= C) return 0;
  if (r == R - 1 && c == C - 1) return 1;
  if (memo[r][c] != -1) return memo[r][c];
  memo[r + 1][c] = solve(r + 1, c, R, C);
  memo[r][c + 1] = solve(r, c + 1, R, C);
  return memo[r + 1][c] + memo[r][c + 1];
}
int main() {
  for (int i = 0; i < N; i++) memo[i].fill(-1);
  int m, n; cin >> m >> n;
  cout << solve(0, 0, m, n) << endl;
  return 0;
}
