#include <bits/stdc++.h>
using namespace std;
array<size_t, 1000> memo{0};
size_t solve(size_t n) {
  if (n <= 3) return n;
  if (memo[n]) {
    clog << "found in memo: " << n << endl;
    return memo[n];
  }
  memo[n] = solve(n - 1) + solve(n - 2);
  return memo[n];
}

int main() {
  std::ios_base::sync_with_stdio(false);
  std::cin.tie(nullptr);
  int n; cin >> n;
  cout << solve(n) << std::endl;
  return 0;
}
