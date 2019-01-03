#include <bits/stdc++.h>
using namespace std;
const size_t N = 3, M = 4;
int t[N][M] = {{1, 3, 5, 8},
               {4, 2, 1, 7},
               {4, 3, 2, 3}};
int memo[N][M];
int solve(int i, int j) {
  
  if (!i && !j) return t[0][0];
  if (!i && j) return t[i][j] + solve(i, j - 1);
  if (i && !j) return t[i][j] + solve(i - 1, j);
  return t[i][j] + min(solve(i - 1, j), solve(i, j - 1));
}
int main() {
  ios_base::sync_with_stdio(false);
  cin.tie(nullptr);

  cout << solve(2, 3) << endl;
  return 0;
 }
