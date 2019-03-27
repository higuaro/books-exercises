#include <iostream>
#include <string>
#include <map>
#include <unordered_map>
using namespace std;

int solve(int n) {
  if (n < 0) return 0;
  if (n == 0) return 1;
  return solve(n - 3) + solve(n - 5) + solve(n - 10);
}

unordered_map<int, int> memo;
int solve_memo(int n) {
  if (memo.count(n)) return memo[n];
  if (n < 0) return 0;
  if (n == 0) {
    return 1;
  }
  int t = solve_memo(n - 3) + solve_memo(n - 5) + solve_memo(n - 10);
  memo[n] = t;
  return t;
}

int solve_array(int n) {
  array<int, 10000> arr{0};
  arr[0] = 1;
  for (int i = 1; i <= n; i++) {
    if (i - 3 >= 0) arr[i] += arr[i - 3];
    if (i - 5 >= 0) arr[i] += arr[i - 5];
    if (i - 10 >= 0) arr[i] += arr[i - 10];
  }
  return arr[n];
}
int main() {
  std::ios_base::sync_with_stdio(false);
  cin.tie(nullptr);
  int n; cin >> n;
  cout << solve_array(n) << endl;
  cout << solve_memo(n) << endl;
  cout << solve(n) << endl;
}
