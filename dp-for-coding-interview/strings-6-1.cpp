#include <string>
#include <iostream>
#include <vector>
int main() {
  std::ios_base::sync_with_stdio(false);
  std::cin.tie(nullptr);
  std::string seq; std::cin >> seq;
  //std::string seq("9430723");
  size_t size = seq.size();
  std::vector<size_t> sum;
  size_t acc = 0;
  for (auto c : seq) {
    sum.push_back(acc);
    acc += static_cast<int>(c - '0');
  }
  sum.push_back(acc);
  for (int l = size - (size & 1); l >= 2; l -= 2) {
    for (int i = 0; i < l; i++) {
      size_t left = sum[i + l / 2] - sum[i];
      size_t right = sum[l + i] - sum[i + l / 2];
      if (left == right) {
        std::cout << l << '\n';
        return 0;
      }
    }
  }
  std::cout << "not found\n";
  return 0;
}
