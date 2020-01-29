#include <bits/stdc++.h>
using namespace std;
template<int N>
int find_best_sum_brute_force(const array<int, N> a) {
  int m = numeric_limits<int>::min();

  array<int, N + 1> sum{0};
  for (int i = 0; i < N; i++) sum[i + 1] = sum[i] + a[i];

  // -2 -3 4 -1 -2 1 5 -3
  for (int i = 0; i < N; i++)
    for (int w = N - i - 1; w >= 1; w--)
      m = max(sum[i + w + 1] - sum[i], m);
  return m;
}
int main() {
  std::ios_base::sync_with_stdio(false);
  std::cin.tie(nullptr);
  const int N = 8;
  array<int, N> a{ -2, -3, 4, -1, -2, 1, 5, -3 };
  cout << find_best_sum_brute_force<N>(a) << endl;
  return 0;
}
