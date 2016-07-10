#include <algorithm>
#include <sstream>
#include "state.h"
#include <gtest/gtest.h>

using namespace std;

class StateTest : public ::testing::Test {
 protected:
  template <class T>
  bool FindPoint(T container, const Point& P) {
    return container.end() !=
           find_if(container.begin(), container.end(), [&P](Point& q) {
	     return Comparator::Compare(P.x, q.x) == Comparator::EQUAL &&
                    Comparator::Compare(P.y, q.y) == Comparator::EQUAL;
	   });
  }

  void DeletePoints(initializer_list<Point> points) {
    for (auto p : points) {
      delete p.x;
      delete p.y;
    }
  }

  string Dump(vector<pair<int,int>> circles) {
    ostringstream oss;
    for (auto x : circles) {
      oss << x.first << "," << x.second << " ";
    }
    return oss.str();
  }
};

TEST_F(StateTest, State_AddPoint) {
  State state;
  EXPECT_TRUE(state.point().empty());
  state.AddPoint(Point(Rational(0,1), Rational(0,1)));
  EXPECT_EQ(1u, state.point().size());
  state.AddPoint(Point(Rational(0,1), Rational(0,1)));
  EXPECT_EQ(1u, state.point().size());
  state.AddPoint(Point(Rational(1,1), Rational(0,1)));
  EXPECT_EQ(2u, state.point().size());
}

TEST_F(StateTest, State_NextCircles) {
  State state;
  state.AddPoint(Point(Rational(0,1), Rational(0,1)));
  state.AddPoint(Point(Rational(1,1), Rational(0,1)));
  state.AddPoint(Point(Rational(2,1), Rational(0,1)));
  auto circles = state.NextCircles();
  vector<pair<int, int>> expected = {{0,1},{0,2},{1,0},{2,0},{2,1}};
  EXPECT_TRUE(expected == circles) <<
      "Expected: " << Dump(expected) <<
      "Actual: " << Dump(circles);
}

TEST_F(StateTest, State_NextLines) {
  State state;
  state.AddPoint(Point(Rational(0,1), Rational(0,1)));
  state.AddPoint(Point(Rational(1,1), Rational(0,1)));
  state.AddPoint(Point(Rational(2,1), Rational(0,1)));
  auto lines = state.NextLines();
  vector<pair<int, int>> expected = {{0,1},{0,2},{1,2}};
  EXPECT_TRUE(expected == lines);
}

TEST_F(StateTest, State_AddCircle) {
  State state;
  state.AddPoint(Point(Rational(0,1), Rational(0,1)));
  state.AddPoint(Point(Rational(1,1), Rational(0,1)));
  state.AddPoint(Point(Rational(-1,1), Rational(0,2)));
  state.AddCircle(0, 1);
  state.AddCircle(1, 2);
  auto circles = state.NextCircles();
  vector<pair<int, int>> expected = {{1,0},{2,0},{2,1}};
  EXPECT_TRUE(expected == circles);
}

TEST_F(StateTest, State_AddLine) {
  State state;
  state.AddPoint(Point(Rational(0,1), Rational(0,1)));
  state.AddPoint(Point(Rational(1,1), Rational(0,1)));
  state.AddPoint(Point(Rational(0,1), Rational(1,2)));
  state.AddLine(0, 1);
  auto lines = state.NextLines();
  vector<pair<int, int>> expected = {{0,2},{1,2}};
  EXPECT_TRUE(expected == lines);
}

TEST_F(StateTest, Intersection_LineCircle_NoSolutions) {
  Point P(Rational(-2,1), Rational(1,2));
  Point Q(Rational(-2,1), Rational(1,3));
  Point A(Rational(0,1), Rational(0,1));
  Point B(Rational(1,1), Rational(0,1));
  auto ans = Intersection::LineCircle(P, Q, A, B);
  EXPECT_TRUE(ans.empty());
  DeletePoints({P, Q, A, B});
}

TEST_F(StateTest, Intersection_LineCircle_OneSolution) {
  Point P(Rational(-1,1), Rational(1,2));
  Point Q(Rational(-1,1), Rational(1,3));
  Point A(Rational(0,1), Rational(0,1));
  Point B(Rational(1,1), Rational(0,1));
  auto ans = Intersection::LineCircle(P, Q, A, B);
  ASSERT_EQ(1u, ans.size());
  Point X(Rational(-1,1), Rational(0,1));
  EXPECT_TRUE(FindPoint(ans, X));
  DeletePoints({P, Q, A, B, X, ans[0]});
}

TEST_F(StateTest, Intersection_LineCircle_TwoSolutions) {
  Point P(Rational(0,2), Rational(1,2));
  Point Q(Rational(0,2), Rational(1,3));
  Point A(Rational(0,1), Rational(0,1));
  Point B(Rational(1,1), Rational(0,1));
  auto ans = Intersection::LineCircle(P, Q, A, B);
  ASSERT_EQ(2u, ans.size());
  Point X(Rational(0,1), Rational(1,1));
  Point Y(Rational(0,1), Rational(-1,1));  
  EXPECT_TRUE(FindPoint(ans, X));
  EXPECT_TRUE(FindPoint(ans, Y));
  DeletePoints({P, Q, A, B, X, Y, ans[0], ans[1]});
}

TEST_F(StateTest, Intersection_LineLine_NoSolutions) {
  Point P(Rational(0,1), Rational(0,1));
  Point Q(Rational(1,1), Rational(0,1));
  Point A(Rational(0,1), Rational(1,1));
  Point B(Rational(1,1), Rational(1,1));
  auto ans = Intersection::LineLine(P, Q, A, B);
  EXPECT_TRUE(ans.empty());
  DeletePoints({P, Q, A, B});
}

TEST_F(StateTest, Intersection_LineLine_OneSolution) {
  Point P(Rational(1,2), Rational(0,1));
  Point Q(Rational(1,3), Rational(0,1));
  Point A(Rational(0,1), Rational(1,4));
  Point B(Rational(0,1), Rational(1,5));
  auto ans = Intersection::LineLine(P, Q, A, B);
  ASSERT_EQ(1u, ans.size());
  Point X(Rational(0,1), Rational(0,1));
  EXPECT_TRUE(FindPoint(ans, X));
  DeletePoints({P, Q, A, B, X, ans[0]});
}

TEST_F(StateTest, Intersection_CircleCircle_NoSolutions) {
  Point P(Rational(0,1), Rational(0,1));
  Point Q(Rational(1,1), Rational(0,1));
  Point A(Rational(-4,1), Rational(0,1));
  Point B(Rational(-3,1), Rational(0,1));
  auto ans = Intersection::CircleCircle(P, Q, A, B);
  EXPECT_TRUE(ans.empty());
  DeletePoints({P, Q, A, B});
}

TEST_F(StateTest, Intersection_CircleCircle_OneSolution) {
  Point P(Rational(0,1), Rational(-1,1));
  Point Q(Rational(1,1), Rational(-1,1));
  Point A(Rational(0,1), Rational(1,1));
  Point B(Rational(1,1), Rational(1,1));
  auto ans = Intersection::CircleCircle(P, Q, A, B);
  ASSERT_EQ(1u, ans.size());
  Point X(Rational(0,1), Rational(0,1));
  EXPECT_TRUE(FindPoint(ans, X));
  DeletePoints({P, Q, A, B, X, ans[0]});
}

TEST_F(StateTest, Intersection_CircleCircle_TwoSolutions) {
  Point P(Rational(-1,1), Rational(0,1));
  Point Q(Rational(1,1), Rational(0,1));
  Point A(Rational(1,1), Rational(0,1));
  Point B(Rational(-1,1), Rational(0,1));
  auto ans = Intersection::CircleCircle(P, Q, A, B);
  ASSERT_EQ(2u, ans.size());
  Point X(Rational(0,1), Sqrt(Rational(3,1)));
  Point Y(Rational(0,1), nSqrt(Rational(3,1)));
  EXPECT_TRUE(FindPoint(ans, X));
  EXPECT_TRUE(FindPoint(ans, Y));
  DeletePoints({P, Q, A, B, X, Y, ans[0], ans[1]});
}

TEST_F(StateTest, BFS_Step) {
  State initial;
  initial.AddPoint(Point(Rational(0,1), Rational(0,1)));
  initial.AddPoint(Point(Rational(1,1), Rational(0,1)));
  BFS bfs(initial);
  while (bfs.Step()) {}
}
