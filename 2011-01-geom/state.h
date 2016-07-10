#include <vector>
#include <set>
#include <queue>
#include "number.h"

struct Point {
  Point(const Number* x_, const Number* y_): x(x_), y(y_) {}
  const Number* x;
  const Number* y;
};

class Intersection {
 public:
  static const std::vector<Point> LineCircle(
      const Point& P, const Point& Q, const Point& A, const Point& B);
  static const std::vector<Point> LineLine(
      const Point& P, const Point& Q, const Point& A, const Point& B);
  static const std::vector<Point> CircleCircle(
      const Point& P, const Point& Q, const Point& A, const Point& B);
  static bool SameCircle(
      const Point& P, const Point& Q, const Point& A, const Point& B);
};

class State {
 public:
  State() {}
  State(const State& old);
  ~State();
  const std::vector<Point>& point() const { return point_; }
  void AddPoint(const Point& p);
  const std::vector<std::pair<int, int>> NextCircles() const;
  const std::vector<std::pair<int, int>> NextLines() const;
  void AddCircle(int a, int b);
  void AddLine(int a, int b);
  void UpdateLine(int a, int b);
  void UpdateCircle(int a, int b);
  std::string ToString() const;
 private:
  bool CheckCircle(int i, int j) const;
  std::vector<Point> point_;
  std::vector<std::pair<int,int>> circle_;
  std::set<std::pair<int,int>> circle_set_;
  std::vector<std::pair<int,int>> line_;
  std::set<std::pair<int,int>> line_set_;
};

class BFS {
 public:
   BFS(const State& start);
   bool Step();
 private:
   std::queue<State> next_state_;
};
