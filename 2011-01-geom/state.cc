#include <vector>
#include <memory>
#include <sstream>
#include "state.h"

using namespace std;

State::~State() {
  for (auto it : point_) {
    delete it.x;
    delete it.y;
  }
}

State::State(const State& old) : circle_(old.circle_),
                                 circle_set_(old.circle_set_),
				 line_(old.line_),
				 line_set_(old.line_set_) {
  for (auto p : old.point_) {
    point_.push_back(Point(p.x->Simplify(), p.y->Simplify()));
  }
}

void State::AddPoint(const Point& p) {
  for (auto it : point_) {
    if (Comparator::Compare(it.x, p.x) == Comparator::EQUAL &&
        Comparator::Compare(it.y, p.y) == Comparator::EQUAL) {
     delete p.x;
     delete p.y;
     return;
    }
  }
  point_.push_back(p);
}

bool State::CheckCircle(int i, int j) const {
  if (i == j)
    return false;
  if (circle_set_.find(make_pair(i,j)) != circle_set_.end())
    return false; 
  for (auto k = 0; k < j; k++)
    if (Intersection::SameCircle(point_[i], point_[j], point_[i], point_[k]))
      return false;
  return true;     
}

const vector<pair<int,int>> State::NextCircles() const {
  vector<pair<int,int>> circles;
  for (auto i = 0u; i < point_.size(); i++)
    for (auto j = 0u; j < point_.size(); j++)
      if (CheckCircle(i, j))
        circles.push_back(make_pair(i,j));
  return circles;
}

const vector<pair<int,int>> State::NextLines() const {
  vector<pair<int,int>> lines;
  for (auto i = 0u; i < point_.size(); i++) {
    for (auto j = i + 1; j < point_.size(); j++) {
      if (line_set_.find(make_pair(i,j)) == line_set_.end()) {
	lines.push_back(make_pair(i,j));
      }
    }
  }
  return lines;
}

void State::AddCircle(int a, int b) {
  circle_.push_back(make_pair(a, b));
  circle_set_.insert(make_pair(a, b));
}

void State::AddLine(int a, int b) {
  line_.push_back(make_pair(a, b));
  line_set_.insert(make_pair(a, b));
}

void State::UpdateLine(int a, int b) {
  for (auto x : line_) {
    auto ans = Intersection::LineLine(
      point_[x.first], point_[x.second], point_[a], point_[b]);
    for (auto k : ans) {
      AddPoint(k);
    }
  }
  for (auto x : circle_) {
    auto ans = Intersection::LineCircle(
      point_[a], point_[b], point_[x.first], point_[x.second]);
    for (auto k : ans) {
      AddPoint(k);
    }
  }
}

void State::UpdateCircle(int a, int b) {
  cout << "adding lines\n";
  for (auto x : line_) {
    auto ans = Intersection::LineCircle(
      point_[x.first], point_[x.second], point_[a], point_[b]);
    for (auto k : ans) {
      AddPoint(k);
    }
  }
  cout << "adding circles\n";
  for (auto x : circle_) {
    cout << "adding circle " << a <<","<<b << " with "<<x.first<<","<<x.second
    <<"\n";
    auto ans = Intersection::CircleCircle(
      point_[a], point_[b], point_[x.first], point_[x.second]);
    cout << "circle added\n";
    for (auto k : ans) {
      AddPoint(k);
    }
  }
}

string State::ToString() const {
  stringstream out;
  out << "state --\n";
  for (auto p : point_) {
    out << "point: " << p.x->ToString() << " , " << p.y->ToString() << "\n";
  }
  for (auto c : circle_) {
    out << "circle: " << c.first << " , " << c.second << "\n";
  }
  for (auto x : line_) {
    out << "line: " << x.first << " , " << x.second << "\n";
  }
  return out.str();
}

static const Number* Square(const Number* x) {
  unique_ptr<const Number> x_(x);
  return Mul(x_->Simplify(), x_->Simplify());
}

static const Number* Sub(const Number* a, const Number* b) {
  return Add(a->Simplify(), Mul(Rational(-1,1), b->Simplify()));
}

static const Number* TakeSub(const Number* a, const Number* b) {
  return Add(a, Mul(Rational(-1,1), b));
}

static Point LineParam(const Point& P, const Point& Q, const Number* t) {
  const Number* x = Add(P.x->Simplify(),
                        Mul(t->Simplify(),
			    Sub(Q.x, P.x)));
  const Number* y = Add(P.y->Simplify(),
                        Mul(t->Simplify(),
	   	            Sub(Q.y, P.y)));
  auto ans = Point(x->Simplify(), y->Simplify());		
  delete t;
  delete x;
  delete y;
  return ans;			    
}

const vector<Point> Intersection::LineCircle(
    const Point& P, const Point& Q, const Point& A, const Point& B) {
  vector<Point> ans;
  const Number* a = Add(Square(Sub(Q.x, P.x)),
                        Square(Sub(Q.y, P.y)));
  const Number* b = Mul(Rational(2,1),
                        Add(Mul(Sub(P.x, A.x),
			        Sub(Q.x, P.x)),
			    Mul(Sub(P.y, A.y),
			        Sub(Q.y, P.y))));
  const Number* c = TakeSub(Add(Square(Sub(P.x, A.x)),
                                Square(Sub(P.y, A.y))),
                            Add(Square(Sub(B.x, A.x)),
                                Square(Sub(B.y, A.y))));
  const Number* delta = Add(Mul(b->Simplify(), b->Simplify()),
                            Mul(Rational(-4,1), 
			        Mul(a->Simplify(), c->Simplify())));
  unique_ptr<const Number> a_(a);				
  unique_ptr<const Number> b_(b);				
  unique_ptr<const Number> c_(c);				
  unique_ptr<const Number> delta_(delta);
  unique_ptr<const Number> zero(Rational(0,1));
  cout << "before compare\n";
  auto compare = Comparator::Compare(delta, zero.get());
  cout << "after compare\n";
  if (compare == Comparator::LESSER)
    return ans;
  if (compare == Comparator::EQUAL) {
    const Number* t = Div(b->Simplify(),
			  Mul(Rational(-2,1),
			      a->Simplify()));
    ans.push_back(LineParam(P, Q, t));
    return ans;
  }
  const Number* t1 = Div(TakeSub(Sqrt(delta->Simplify()),
                             b->Simplify()),
			 Mul(Rational(2,1),
			     a->Simplify()));
  const Number* t2 = Div(TakeSub(nSqrt(delta->Simplify()),
                             b->Simplify()),
			 Mul(Rational(2,1),
			     a->Simplify()));
  ans.push_back(LineParam(P, Q, t1));			     
  ans.push_back(LineParam(P, Q, t2));
  return ans;
}

const vector<Point> Intersection::LineLine(
    const Point& P, const Point& Q, const Point& A, const Point& B) {
  vector<Point> ans;
  const Number* den = TakeSub(Mul(Sub(B.x, A.x),
                                  Sub(Q.y, P.y)),
			      Mul(Sub(B.y, A.y),
			          Sub(Q.x, P.x)));
  unique_ptr<const Number> zero(Rational(0,1));
  if (Comparator::Compare(den, zero.get()) == Comparator::EQUAL) {
    delete den;
    return ans;
  }
  const Number* num = TakeSub(Mul(Sub(A.y, P.y),
                                  Sub(Q.x, P.x)),
			      Mul(Sub(A.x, P.x),
			          Sub(Q.y, P.y)));
  const Number* s = Div(num, den);
  const Number* x = Add(A.x->Simplify(),
                        Mul(Sub(B.x, A.x),
			    s->Simplify()));
  const Number* y = Add(A.y->Simplify(),
                        Mul(Sub(B.y, A.y),
			    s));
  ans.push_back(Point(x->Simplify(), y->Simplify()));
  delete x;
  delete y;
  return ans;
}

const vector<Point> Intersection::CircleCircle(
    const Point& P, const Point& Q, const Point& A, const Point& B) {
  vector<Point> ans;
  const Number* R1 = Sqrt(Add(Square(Sub(B.x, A.x)),
                              Square(Sub(B.y, A.y))));
  const Number* R2 = Sqrt(Add(Square(Sub(Q.x, P.x)),
                              Square(Sub(Q.y, P.y))));
  const Number* d = Sqrt(Add(Square(Sub(P.x, A.x)),
                             Square(Sub(P.y, A.y))));
  const Number* R = Mul(TakeSub(Square(Add(R1->Simplify(),
                                           R2->Simplify())),
		                Square(d->Simplify())),
		        TakeSub(Square(d->Simplify()),
			        Square(Sub(R2, R1))));
  unique_ptr<const Number> R1_(R1);
  unique_ptr<const Number> R2_(R2);
  unique_ptr<const Number> d_(d);
  unique_ptr<const Number> R_(R);
  cout << "before compare\n";
  //auto compare = Comparator::Compare(R, zero.get());
  auto sign = R->GetSign();
  cout << "after compare\n";
  //if (compare == Comparator::LESSER) {
  if (sign == Number::NEGATIVE) {
    return ans;
  }
  cout << "step 1\n";
  const Number* x1 = Add(Mul(Rational(1,2),
                             Add(A.x->Simplify(),
			         P.x->Simplify())),
		         Div(Mul(Sub(P.x, A.x),
			         TakeSub(Square(R1->Simplify()),
				         Square(R2->Simplify()))),
			     Mul(Rational(2,1),
			         Square(d->Simplify()))));
  cout << "step 2\n";
  const Number* y1 = Add(Mul(Rational(1,2),
                             Add(A.y->Simplify(),
			         P.y->Simplify())),
		         Div(Mul(Sub(P.y, A.y),
			         TakeSub(Square(R1->Simplify()),
				         Square(R2->Simplify()))),
			     Mul(Rational(2,1),
			         Square(d->Simplify()))));
  //if (compare == Comparator::EQUAL) {
  cout << "step 3\n";
  if (sign == Number::ZERO) {
    return ans;
    ans.push_back(Point(x1->Simplify(), y1->Simplify()));
    delete x1;
    delete y1;
    return ans;
  }
  cout << "step 4\n";
  const Number* x2 = Mul(Sqrt(R->Simplify()),
                         Div(Sub(P.y, A.y),
			     Mul(Rational(2,1),
			         Square(d->Simplify()))));
  cout << "step 5\n";
  const Number* y2 = Mul(Sqrt(R->Simplify()),
                         Div(Sub(P.x, A.x),
			     Mul(Rational(2,1),
			         Square(d->Simplify()))));
  cout << "step 6\n";
  cout << "x1 o: "<< x1->ToString() << "\n";
  cout << "x2 o: "<< x2->ToString() << "\n";
  cout << "x1: "<< x1->Simplify()->ToString() << "\n";
  cout << "x2: "<< x2->Simplify()->ToString() << "\n";
  cout << "y1: "<< y1->Simplify()->ToString() << "\n";
  cout << "y1: "<< y2->Simplify()->ToString() << "\n";
  auto p1 = 
  Point(Add(x1->Simplify(), x2->Simplify()),
                      TakeSub(y1->Simplify(), y2->Simplify()));
  cout << "step 6.5\n";
  ans.push_back(p1);
  cout << "step 7\n";
  ans.push_back(Point(TakeSub(x1->Simplify(), x2->Simplify()),
                      Add(y1->Simplify(), y2->Simplify())));
  cout << "delete and return\n";
  delete x1;
  delete x2;
  delete y1;
  delete y2;
  return ans;
}

bool Intersection::SameCircle(
    const Point& P, const Point& Q, const Point& A, const Point& B) {
  if (Comparator::Compare(P.x, A.x) != Comparator::EQUAL) {
    return false;
  }
  if (Comparator::Compare(P.y, A.y) != Comparator::EQUAL) {
    return false;
  }
  unique_ptr<const Number> d1(Add(Square(Sub(P.x, Q.x)),
                                  Square(Sub(P.y, Q.y))));
  unique_ptr<const Number> d2(Add(Square(Sub(A.x, B.x)),
                                  Square(Sub(A.y, B.y))));
  return Comparator::Compare(d1.get(), d2.get()) == Comparator::EQUAL;
}

BFS::BFS(const State& start) {
  next_state_.push(start);
}

bool BFS::Step() {
  if (next_state_.empty()) {
    return false;
  }
  auto current = next_state_.front();
  next_state_.pop();
  cout << current.ToString();
  for (auto line : current.NextLines()) {
    State state(current);
    cout << "going to add line " << line.first <<  "," << line.second << "\n";
    state.UpdateLine(line.first, line.second);
    state.AddLine(line.first, line.second);
    next_state_.push(state);
  }
  for (auto circle : current.NextCircles()) {
    State state(current);
    cout << "going to update circle " << circle.first <<  "," << 
        circle.second << "\n";
    state.UpdateCircle(circle.first, circle.second);
    cout << "going to add circle " << circle.first <<  "," << 
        circle.second << "\n";
    state.AddCircle(circle.first, circle.second);
    cout << "push\n";
    next_state_.push(state);
  }
  cout << "ending\n";
  return true;
}
