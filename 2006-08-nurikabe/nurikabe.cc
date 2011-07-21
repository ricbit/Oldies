/* ex: set tabstop=2 expandtab: */

#include "nurikabe.h"

using namespace std;

// Generic tools -------------------------------------------------

template <class T>
T abs(T a) {
  return a>0?a:-a;
}

string single_digit(int n) {
  string s=" ";
  s[0]=n<10?'0'+n:'A'+n-10;
  return s;
}

// Cell ----------------------------------------------------------

class Group;
typedef boost::shared_ptr<Group> pGroup;

class Cell {
public:	
  enum {BLACK, WHITE, GRAY, EDGE};
  int color;
  int number;
  bool grouped;
  bool hard;
  pGroup group;

  Cell(): color(GRAY),number(0),grouped(false),hard(false) {}
};

// CellPos -------------------------------------------------------

class CellPos {
public:
  int x,y;
  CellPos (int _x, int _y):x(_x),y(_y) {}
  ~CellPos() {}
  bool operator== (CellPos &a) {
    return x==a.x && y==a.y;
  }
  int operator- (CellPos &a) {
    return abs(x-a.x)+abs(y-a.y);
  }
};

ostream& operator<< (ostream &os, const CellPos &c) {
  return os << "(" << c.x << "," << c.y << ")";
}

typedef boost::shared_ptr<CellPos> pCellPos;

struct pCellPosOrder {
  bool operator()(pCellPos p1, pCellPos p2) const {
    return (p1->x==p2->x)?(p1->y<p2->y):(p1->x<p2->x);
  }
} pCellPosCompare;

typedef set<pCellPos,pCellPosOrder> setCellPos;

void set_intersection (setCellPos a, setCellPos b, setCellPos &c) {
  insert_iterator<setCellPos> it(c,c.begin());
  set_intersection (a.begin(),a.end(),b.begin(),b.end(),it,pCellPosCompare);
}

void set_union (setCellPos a, setCellPos b, setCellPos &c) {
  insert_iterator<setCellPos> it(c,c.begin());
  set_union (a.begin(),a.end(),b.begin(),b.end(),it,pCellPosCompare);
}

// Group ---------------------------------------------------------

class Table;
class DistanceMap;

class Group {
public:
  int size,current,color;
  Table *table;
  setCellPos group,boundary;
  DistanceMap *map;
  Group(int x, int y, int number, Table *t, int c);
  Group(Group a, Group b);
  ~Group();
  Group(Group const&g);
  void add (pCellPos cell) {
    add (cell->x,cell->y);
  }
  void add (int x, int y);
  void update_boundaries(void);
  void clear_boundaries(void);
  bool is_boundary(pCellPos cell);
  bool is_boundary(int x, int y);
};

// DistanceMap ---------------------------------------------------

class DistanceMap;

typedef boost::shared_ptr<DistanceMap> pDistanceMap;
typedef boost::multi_array<int,2> map_array;

class DistanceMap {
public:
  map_array map,reach;
  boost::multi_array<bool,2> boundary,path;
  vector<setCellPos> histogram;
  Table *table;
  int sx,sy;
  bool locked;

  static const int EMPTY=10000;

  DistanceMap (Table *t);
  void merge (DistanceMap *p);
  void update (pGroup p);
  bool trim(void);
  bool check (map_array &m, int x, int y);
  void find_path (int x, int y);
  void set_path (void);
  bool update_path(void);
  int get (int i, int j) {return ((i<0)||(i>sx)||(j<0)||(j>sy))?EMPTY:map[i][j];}
  void build_map (map_array &m, setCellPos group, setCellPos boundary, int limit);
};

ostream& operator<< (ostream &os, const DistanceMap &d);

// Table ---------------------------------------------------------

class Table {
public:
  boost::multi_array<Cell,2> table;
  enum {SOLVED, UNSOLVED, IMPOSSIBLE, MULTIPLE};

  list<pGroup> hard,black,soft;
  int sx,sy,black_size,level;
  bool verbose,extra,distance;

  Table (int x, int y);
  Table (Table &t);
  ~Table();
  Cell &get (int x, int y);
  Cell &get (pCellPos p);
  void init(void);
  void setNumber (int x, int y, int number);
  void insert_soft (int x, int y);
  void insert_black (int x, int y);
  int solve(void);
  void update_hard(void);
  bool extend_groups(list<pGroup> group);
  bool create_black_groups(void);
  bool merge_black(void);
  void merge_black(pGroup p, pGroup q);
  bool merge_soft(void);
  int count_boundaries(int i,int j, pGroup p);
  bool finished(void);
};

// BugException --------------------------------------------------

/// Thrown when the puzzle is unsolvable
class BugException {
  // nothing really
} bug;

// Solution ------------------------------------------------------

/// Implements a solution method
class Solution {
public:
  /// try to apply the method implemented by the class
  virtual bool solve (Table *t)=0;

  /// return the name of the method implemented by the class
  virtual string name(void)=0;

  /// return a predicted computational cost of this method
  virtual int cost(void)=0;
  virtual ~Solution() {}
};

typedef boost::shared_ptr<Solution> pSolution;

struct pSolutionOrder {
  bool operator()(pSolution p1, pSolution p2) const {
    return p1->cost()<p2->cost();
  }
} pSolutionCompare;

// clear_complete_groups ----------------------------------------

/** When a hard white group is complete, 
    this method clear all the cells on the boundary of the group */
class clear_complete_groups: public Solution {
public:
  bool solve (Table *t);
  bool algorithm (Table *t);
  string name(void) {return "Clear complete groups";}
  int cost(void) {return 1;}
};

bool clear_complete_groups::solve (Table *t) {
  bool changed=algorithm(t);
  if (changed)
    t->create_black_groups();
  return changed;
}

bool clear_complete_groups::algorithm (Table *t) {
  BOOST_FOREACH (pGroup p, t->hard)
    if (p->size==p->current) {
      p->update_boundaries();
      p->clear_boundaries();
      t->hard.remove(p);
      solve(t);
      return true;
    }

  return false;
}

// clear_shared_cells -------------------------------------------

/** If a cell is boundary to two hard groups,
    then it must be black */
class clear_shared_cells: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Clear shared cells";}
  int cost(void) {return 100;}
};

bool clear_shared_cells::solve (Table *t) {
  bool changed=false;

  BOOST_FOREACH (pGroup p, t->hard)
    p->update_boundaries();

  BOOST_FOREACH (pGroup p, t->hard)
    BOOST_FOREACH (pGroup q, t->hard)
      if (p<q) {
	setCellPos result;
	set_intersection(p->boundary,q->boundary,result);
        BOOST_FOREACH (pCellPos cell,result) {
          t->get(cell).color=Cell::BLACK;
          changed=true;
	}
      }

  if (changed)
    t->create_black_groups();
  return changed;
}

// check_bugs ---------------------------------------------------

/** Check if we violated some rule of the game */
class check_bugs: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Check bugs";}
  int cost(void) {return 1;}
};

bool check_bugs::solve (Table *t) {
  // try to merge hard with hard
  BOOST_FOREACH (pGroup p,t->hard)
    BOOST_FOREACH (pGroup q,t->hard)
      if (p<q)
      BOOST_FOREACH (pCellPos c1, p->group)
	BOOST_FOREACH (pCellPos c2, q->group)
	  if (*c1-*c2==1)
	    throw bug;

  // check if a hard group is greater than it should be
  BOOST_FOREACH (pGroup p, t->hard)
    if (p->current>p->size)
      throw bug;

  // check if a hard group is closed and smaller than it should be
  BOOST_FOREACH (pGroup p, t->hard) {
    p->update_boundaries();
    if (p->current<p->size && p->boundary.size()==0)
      throw bug;
  }

  // check if there's a 2x2 black region on the table
  for (int i=0; i<t->sx-1; i++)
    for (int j=0; j<t->sy-1; j++)
      if (t->get(i,j).color==Cell::BLACK &&
	  t->get(i+1,j).color==Cell::BLACK &&
	  t->get(i+1,j+1).color==Cell::BLACK &&
	  t->get(i,j+1).color==Cell::BLACK)
      {
        throw bug;
      }

  return false;
}

// extend_hard_groups -------------------------------------------

/** If a hard group has a single cell on its boundary,
    then extends it */
class extend_hard_groups: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Extend hard groups";}
  int cost(void) {return 10;}
};

bool extend_hard_groups::solve (Table *t) {
  bool changed=t->extend_groups(t->hard);
  if (changed)
    t->merge_soft();
  return changed;
}

// limited_growth -----------------------------------------------

/** */
class limited_growth: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Limited growth";}
  int cost(void) {return 3000;}
};

bool limited_growth::solve (Table *t) {
  t->update_hard();

  BOOST_FOREACH (pGroup p, t->hard)
    p->update_boundaries();

  BOOST_FOREACH (pGroup h, t->hard) {
    h->map->update(h);
    BOOST_FOREACH (pCellPos pivot, h->boundary) {
      setCellPos test_boundary;
      BOOST_FOREACH (pCellPos cell, h->boundary)
	if (cell!=pivot)
	  test_boundary.insert(cell);
      h->map->build_map(h->map->reach,h->group,test_boundary,h->size-h->current);
      //cout << *(h->map);
      if (h->map->reach[pivot->x][pivot->y]==DistanceMap::EMPTY) {
        int count=0;
	for (int i=0; i<t->sx; i++)
	  for (int j=0; j<t->sy; j++)
	    if (h->map->reach[i][j]!=DistanceMap::EMPTY)
	      count++;
        if (count<h->size) {
          pGroup p(new Group(pivot->x,pivot->y,0,t,Cell::WHITE));
          t->soft.push_back(p);
          t->merge_soft();
          return true;
	}
      }
    }
  }
  return false;
}

// extend_toward_hard -------------------------------------------

/** Check all the boundaries of a soft group,
    if only one of them leads toward a hard group,
    then it must be white */
class extend_toward_hard: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Extend toward hard";}
  int cost(void) {return 2000;}
private:
  int *visited;
  int sx,sy;
  Table *table;
  bool find_hard(int x, int y);
};

bool extend_toward_hard::find_hard(int x, int y) {
  if (x<0 || x>=sx || y<0 || y>=sy)
    return false;

  if (visited[x+y*sx])
    return false;

  visited[x+y*sx]=true;

  if (table->get(x,y).hard && table->get(x,y).color==Cell::WHITE)
    return true;

  if (table->get(x,y).hard)
    return false;

  if (find_hard(x+1,y))
    return true;
  if (find_hard(x-1,y))
    return true;
  if (find_hard(x,y+1))
    return true;
  if (find_hard(x,y-1))
    return true;

  return false;
}

bool extend_toward_hard::solve (Table *t) {
  t->update_hard();

  table=t;
  sx=t->sx;
  sy=t->sy;
  visited=new int[sx*sy];
  BOOST_FOREACH (pGroup s, t->soft) {
    pCellPos boundary;
    int count=0;

    s->update_boundaries();
    BOOST_FOREACH (pCellPos cell, s->boundary) {
      for (int i=0; i<sx*sy; i++)
	visited[i]=false;
      BOOST_FOREACH (pCellPos c, s->group)
	visited[c->x+sx*c->y]=true;
      if (find_hard (cell->x,cell->y)) {
	count++;
	boundary=cell;
      }
    }
    if (count==1) {
      pGroup p(new Group(boundary->x,boundary->y,0,t,Cell::WHITE));
      t->soft.push_back(p);
      t->merge_soft();
      delete []visited;
      return true;
    }
  }

  delete []visited;
  return false;
}

// update_path --------------------------------------------------

/** Sometimes a path may take more than one route to reach
    the hard group. If you find which route is true, then
    you can safely set the other routes to black */
class update_path: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Update path";}
  int cost(void) {return 20;}
};

bool update_path::solve (Table *t) {
  bool changed=false;

  BOOST_FOREACH (pGroup p, t->hard)
    if (p->map->locked)
      changed=p->map->update_path() || changed;

  if (changed)
    t->create_black_groups();

  return changed;
}

// block_implication --------------------------------------------

/** When a 2x2 block has two blacks and two grays, and the 
    only path leading to one of grays pass through the other,
    then the latter must be white */
class block_implication: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Block implication";}
  int cost(void) {return 200;}
private:
  bool changed;
  Table *table;
  void check_block (pCellPos p1, pCellPos p2, pCellPos p3, pCellPos p4);
};

void block_implication::check_block (pCellPos p1, pCellPos p2, pCellPos p3, pCellPos p4) {
  if (table->get(p1).color==Cell::BLACK &&
      table->get(p2).color==Cell::BLACK &&
      table->get(p3).color==Cell::GRAY &&
      table->get(p4).color==Cell::GRAY)
  {
    int count=0;
    pCellPos q[4];
    q[0]=pCellPos(new CellPos(p4->x+1,p4->y));
    q[1]=pCellPos(new CellPos(p4->x-1,p4->y));
    q[2]=pCellPos(new CellPos(p4->x,p4->y+1));
    q[3]=pCellPos(new CellPos(p4->x,p4->y-1));
    for (int i=0; i<4; i++)
      if (table->get(q[i]).color==Cell::BLACK || table->get(q[i]).color==Cell::EDGE)
        count++;
    if (count==3) {
      pGroup p(new Group(p3->x,p3->y,0,table,Cell::WHITE));
      table->soft.push_back(p);
      changed=true;
    }
  }
}

bool block_implication::solve (Table *t) {
  changed=false;
  table=t;

  for (int i=0; i<t->sx-1; i++)
    for (int j=0; j<t->sy-1; j++) {
      pCellPos p1=pCellPos(new CellPos(i,j));
      pCellPos p2=pCellPos(new CellPos(i+1,j));
      pCellPos p3=pCellPos(new CellPos(i,j+1));
      pCellPos p4=pCellPos(new CellPos(i+1,j+1));

      check_block (p1,p2,p3,p4);
      check_block (p1,p2,p4,p3);

      check_block (p2,p4,p1,p3);
      check_block (p2,p4,p3,p1);

      check_block (p3,p4,p1,p2);
      check_block (p3,p4,p2,p1);

      check_block (p1,p3,p2,p4);
      check_block (p1,p3,p4,p2);
    }

  if (changed)
    t->merge_soft();

  return changed;
}

// extend_black_groups ------------------------------------------

/** If a black group has a single cell on its boundary,
    then extends it */
class extend_black_groups: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Extend black groups";}
  int cost(void) {return 10;}
};

bool extend_black_groups::solve (Table *t) {
  bool changed=t->extend_groups(t->black);
  if (changed)
    t->merge_black();
  return changed;
}

// extend_soft_groups -------------------------------------------

/** If a soft group has a single cell on its boundary,
    then extends it */
class extend_soft_groups: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Extend soft groups";}
  int cost(void) {return 10;}
};

bool extend_soft_groups::solve (Table *t) {
  bool changed=t->extend_groups(t->soft);
  if (changed)
    t->merge_soft();
  return changed;
}

// erase_unreachables -------------------------------------------

/** If a cell can't reach any hard group,
    then it must be black */
class erase_unreachables: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Erase unreachables";}
  int cost(void) {return 1000;}
};

bool erase_unreachables::solve (Table *t) {
  DistanceMap map(t);

  t->update_hard();

  BOOST_FOREACH (pGroup p, t->hard)
    p->update_boundaries();

  BOOST_FOREACH (pGroup p, t->hard) {
    p->map->update(p);
    map.merge(p->map);
  }

  if (map.trim()) {
    t->create_black_groups();
    return true; 
  }
  return false;
}

// count_reachables ---------------------------------------------

/** If a hard group need X cells to be complete,
    and also can only extends to X cells,
    then all of the X cells must be white */
class count_reachables: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Count reachables";}
  int cost(void) {return 1000;}
};

bool count_reachables::solve (Table *t) {
  bool changed=false;

  t->update_hard();

  BOOST_FOREACH (pGroup p, t->hard)
    p->update_boundaries();

  BOOST_FOREACH (pGroup h, t->hard) 
    if (!h->map->locked) {
      h->map->update(h);
      int count=0;
      for (int i=0; i<t->sx; i++)
        for (int j=0; j<t->sy; j++)
	  if (h->map->map[i][j]!=DistanceMap::EMPTY)
	    count++;

      if (count==h->size)
        for (int i=0; i<t->sx; i++)
          for (int j=0; j<t->sy; j++)
	    if (h->map->map[i][j]!=DistanceMap::EMPTY && t->get(i,j).color==Cell::GRAY) {
              pGroup p(new Group(i,j,0,t,Cell::WHITE));
              t->soft.push_back(p);
	      changed=true;
	    }
    }

  if (changed)
    t->merge_soft();

  return changed;
}

// find_path ----------------------------------------------------

/** Check if a soft group can connect to only one hard group.
    In this case, find the possible paths. */
class find_path: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Find path";}
  int cost(void) {return 1000;}
};

bool find_path::solve (Table *t) {
  bool changed=false;

  BOOST_FOREACH (pGroup s,t->soft)
    s->update_boundaries();

  t->update_hard();

  BOOST_FOREACH (pGroup h,t->hard)
    h->map->update(h);

  BOOST_FOREACH (pGroup s,t->soft) {
    int count=0;
    pGroup root;

    // search for a root
    BOOST_FOREACH (pGroup h,t->hard)
      if (h->size!=h->current) {
        bool found=false;
        BOOST_FOREACH (pCellPos cell,s->boundary)
	  if (h->map->map[cell->x][cell->y]+s->current+h->current<=h->size) {
	    root=h;
            found=true;
  	  }
        if (found)
	  count++;
      }

    // if only one root...
    if (count==1 && !root->map->locked) {
      bool proceed=true;
      BOOST_FOREACH (pCellPos cell,s->boundary)
	if (root->map->map[cell->x][cell->y]+s->current+root->current<root->size)
	  proceed=false;

      if (proceed) {
        BOOST_FOREACH (pCellPos cell,s->boundary)
	  if (root->map->map[cell->x][cell->y]+s->current+root->current==root->size) {
	    root->map->find_path(cell->x,cell->y);
	    changed=true;
          }
        if (changed) {
          BOOST_FOREACH (pCellPos cell,root->group)
	    root->map->path[cell->x][cell->y]=true;
          root->map->locked=true;
          root->map->set_path();
    	  t->merge_soft();
          t->create_black_groups();
	  return true;
        }
      }
    }
  }

  return false;
}

// soft_exceeds_hard --------------------------------------------

/** Check if a soft group cannot join a hard group due
    to exceeding the hard group size.
    In this case the joint is black */
class soft_exceeds_hard: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Soft exceeds hard";}
  int cost(void) {return 100;}
};

bool soft_exceeds_hard::solve (Table *t) {
  bool changed=false;

  BOOST_FOREACH (pGroup p, t->hard)
    p->update_boundaries();

  BOOST_FOREACH (pGroup p, t->soft)
    p->update_boundaries();

  BOOST_FOREACH (pGroup h, t->hard)
    BOOST_FOREACH (pGroup s, t->soft)
      if (h->current+s->current+1>h->size) {
        setCellPos result;
	set_intersection(h->boundary,s->boundary,result);
        BOOST_FOREACH (pCellPos cell, result) {
	  t->get(cell).color=Cell::BLACK;
	  changed=true;
        }
      }
	
  if (changed)
    t->create_black_groups();

  return changed;
}

// tail_implication ---------------------------------------------

/** If a hard group only miss one cell to be complete,
    then any cell that is neighbour to two boundaries
    of this group must be black */
class tail_implication: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Tail implication";}
  int cost(void) {return 100;}
};

bool tail_implication::solve (Table *t) {
  bool changed=false;

  BOOST_FOREACH (pGroup p, t->hard) {
    p->update_boundaries();
    if (p->current==p->size-1) {
      if (p->boundary.size()==2) 
	for (int i=0; i<t->sx; i++)
	  for (int j=0; j<t->sy; j++) 
	    if (t->get(i,j).color==Cell::GRAY)
	      if (t->count_boundaries(i,j,p)>1) {
		t->get(i,j).color=Cell::BLACK;
		changed=true;
	      }
    }
  }

  if (changed)
    t->create_black_groups();

  return changed;
}

// create_elbow -------------------------------------------------

/** Prevents the formation of 2x2 black groups by turning
    elbow cells into white */
class create_elbow: public Solution {
public:
  bool solve (Table *t);
  string name(void) {return "Create elbow";}
  int cost(void) {return 10;}
};

bool create_elbow::solve (Table *t) {
  bool changed=false;

  for (int i=0; i<t->sx; i++)
    for (int j=0; j<t->sy; j++) {
      // case 1: .x/..
      if (t->get(i,j).color==Cell::BLACK &&
 	  t->get(i,j+1).color==Cell::BLACK &&
 	  t->get(i+1,j+1).color==Cell::BLACK &&
	  t->get(i+1,j).color==Cell::GRAY) 
      {
        pGroup p(new Group(i+1,j,0,t,Cell::WHITE));
        t->soft.push_back(p);
 	changed=true;	
      }
      // case 2: ../x.
      if (t->get(i,j).color==Cell::BLACK &&
 	  t->get(i+1,j).color==Cell::BLACK &&
 	  t->get(i+1,j+1).color==Cell::BLACK &&
	  t->get(i,j+1).color==Cell::GRAY) 
      {
        pGroup p(new Group(i,j+1,0,t,Cell::WHITE));
        t->soft.push_back(p);
 	changed=true;	
      }
      // case 3: x./..
      if (t->get(i,j+1).color==Cell::BLACK &&
 	  t->get(i+1,j).color==Cell::BLACK &&
 	  t->get(i+1,j+1).color==Cell::BLACK &&
	  t->get(i,j).color==Cell::GRAY) 
      {
        pGroup p(new Group(i,j,0,t,Cell::WHITE));
        t->soft.push_back(p);
 	changed=true;	
      }
      // case 4: ../.x
      if (t->get(i,j+1).color==Cell::BLACK &&
 	  t->get(i+1,j).color==Cell::BLACK &&
 	  t->get(i,j).color==Cell::BLACK &&
	  t->get(i+1,j+1).color==Cell::GRAY) 
      {
        pGroup p(new Group(i+1,j+1,0,t,Cell::WHITE));
        t->soft.push_back(p);
 	changed=true;	
      }
    }

  if (changed)
    t->merge_soft();
  return changed;
}

// Group (definitions) -------------------------------------------

Group::Group(int x, int y, int number, Table *t, int c):
        size(number),current(0),color(c),table(t)
{
  add(x,y);
  map=new DistanceMap(t);
}

Group::Group(Group const&g): size(g.size), current(g.current),
    color(g.color), table(g.table),
    group(g.group), boundary(g.boundary)
{
  map=new DistanceMap(table);
}

Group::~Group() {
  group.clear();
  boundary.clear();
  delete map;
}

Group::Group(Group a, Group b) {
  size=a.size;
  color=a.color;
  table=a.table;
  set_union(a.group,b.group,group);
  current=group.size();
  map=new DistanceMap(table);
}

bool Group::is_boundary(pCellPos cell) {
  return binary_search (boundary.begin(),boundary.end(),cell,pCellPosCompare);
}

bool Group::is_boundary(int x, int y) {
  return is_boundary(pCellPos(new CellPos(x,y)));
}

void Group::add (int x, int y) {
  pCellPos p(new CellPos(x,y));
  table->get(p).color=color;
  table->get(p).grouped=true;
  group.insert(p);
  current++;
  update_boundaries();
}

void Group::update_boundaries(void) {
  boundary.clear();

  BOOST_FOREACH(pCellPos cell, group) {
    if (table->get(cell->x+1,cell->y).color==Cell::GRAY)
      boundary.insert(pCellPos (new CellPos(cell->x+1,cell->y)));

    if (table->get(cell->x-1,cell->y).color==Cell::GRAY)
      boundary.insert(pCellPos (new CellPos(cell->x-1,cell->y)));

    if (table->get(cell->x,cell->y+1).color==Cell::GRAY)
      boundary.insert(pCellPos (new CellPos(cell->x,cell->y+1)));

    if (table->get(cell->x,cell->y-1).color==Cell::GRAY)
      boundary.insert(pCellPos (new CellPos(cell->x,cell->y-1)));
  }
}

void Group::clear_boundaries(void) {
  BOOST_FOREACH (pCellPos cell, boundary)
    table->get(cell).color=Cell::BLACK;
}

ostream& operator<< (ostream &os, const Group &g) {
  os << "Group size: " << g.size << ", current: " << g.current <<"\n";
  BOOST_FOREACH (pCellPos p, g.group)
    os << *p << '\n';
  BOOST_FOREACH (pCellPos p, g.boundary)
    os << "  B" << (*p) << '\n';
  return os;
}

// DistanceMap (definitions) -------------------------------------

ostream& operator<< (ostream &os, const DistanceMap &d) {
  os << "Map:\n";
  for (int j=0; j<d.table->sy; j++) {
    for (int i=0; i<d.table->sx; i++)
      if (d.map[i][j]==DistanceMap::EMPTY) 
   	os <<".";
      else
	os <<single_digit(d.map[i][j]);
     os <<"\n";
  }
  os <<"\n";

  os << "Reach:\n";
  for (int j=0; j<d.table->sy; j++) {
    for (int i=0; i<d.table->sx; i++)
      if (d.reach[i][j]==DistanceMap::EMPTY) 
   	os <<".";
      else
	os <<single_digit(d.reach[i][j]);
     os <<"\n";
  }
  os <<"\n";
  return os;
}

bool DistanceMap::update_path (void) {
  bool changed=false;

  BOOST_FOREACH (setCellPos s, histogram)
    if (s.size()>1) {
      bool foundW=false,foundG=false;
      BOOST_FOREACH (pCellPos cell,s) {
	if (table->get(cell->x,cell->y).color==Cell::WHITE)
	  foundW=true;
	if (table->get(cell->x,cell->y).color==Cell::GRAY &&
	    map[cell->x][cell->y]!=EMPTY)
	  foundG=true;
      }

      if (foundW && foundG) {
	BOOST_FOREACH (pCellPos cell,s)
	  if (table->get(cell->x,cell->y).color!=Cell::WHITE)
	    map[cell->x][cell->y]=EMPTY;
	changed=true;
      }
    }

  if (changed) {
    bool found;
    int size=histogram.size()-1;

    do {
      found=false;
      for (int i=0; i<sx; i++)
        for (int j=0; j<sy; j++) {
	  if ((map[i][j]>0) && (map[i][j]!=EMPTY) && !(
	      (map[i][j]==get(i+1,j)+1) || (map[i][j]==get(i-1,j)+1) ||
	      (map[i][j]==get(i,j+1)+1) || (map[i][j]==get(i,j-1)+1)))
	  {
	    map[i][j]=EMPTY;
	    found=true;
	  }
	  if ((map[i][j]<size) && !(
	      (map[i][j]==get(i+1,j)-1) || (map[i][j]==get(i-1,j)-1) ||
	      (map[i][j]==get(i,j+1)-1) || (map[i][j]==get(i,j-1)-1)))
	  {
	    map[i][j]=EMPTY;
	    found=true;
	  }
        }
    } while (found);
  }

  return changed;
}

bool DistanceMap::check (map_array &m, int x, int y) {
  return 
    !table->get(x,y).hard && !boundary[x][y] && m[x][y]==EMPTY;
}

void DistanceMap::build_map
  (map_array &m, setCellPos group, setCellPos boundary, int limit)
{
  setCellPos current,next;

  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++)
      m[i][j]=EMPTY;

  BOOST_FOREACH (pCellPos cell,group)
    m[cell->x][cell->y]=0;

  current=boundary;
  next.clear();
  int level=1;
  do {
    BOOST_FOREACH (pCellPos p,current) {
      if (m[p->x][p->y]==EMPTY) {
        m[p->x][p->y]=level;
        if (check(m,p->x+1,p->y))
	  next.insert(pCellPos(new CellPos(p->x+1,p->y)));
        if (check(m,p->x-1,p->y))
	  next.insert(pCellPos(new CellPos(p->x-1,p->y)));
        if (check(m,p->x,p->y+1))
	  next.insert(pCellPos(new CellPos(p->x,p->y+1)));
        if (check(m,p->x,p->y-1))
	  next.insert(pCellPos(new CellPos(p->x,p->y-1)));
      }
    }

    current.clear();
    current=next;
    next.clear();
  } while (level++<limit);

  current.clear();
}

void DistanceMap::update (pGroup p) {
  if (locked) {
    if (table->distance)
      cout << *this;
    return;
  }

  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++) {
      boundary[i][j]=false;
      path[i][j]=false;
    }

  BOOST_FOREACH(pGroup q, table->hard)
    if (p!=q)
      BOOST_FOREACH(pCellPos cell, q->boundary)
        boundary[cell->x][cell->y]=true;

  build_map(map,p->group,p->boundary,p->size-p->current);

  if (table->distance)
    cout << *this;
}

DistanceMap::DistanceMap (Table *t): table(t),locked(false) {
  sx=t->sx; sy=t->sy;
  map.resize(boost::extents[sx][sy]);
  reach.resize(boost::extents[sx][sy]);
  boundary.resize(boost::extents[sx][sy]);
  path.resize(boost::extents[sx][sy]);

  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++)
      map[i][j]=EMPTY;
}

void DistanceMap::merge (DistanceMap *p) {
  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++)
      map[i][j]=min(map[i][j],p->map[i][j]);
}

void DistanceMap::find_path (int x, int y) {
  path[x][y]=true;

  if (!table->get(x+1,y).hard && map[x+1][y]<map[x][y])
    find_path(x+1,y);
  if (!table->get(x-1,y).hard && map[x-1][y]<map[x][y])
    find_path(x-1,y);
  if (!table->get(x,y+1).hard && map[x][y+1]<map[x][y])
    find_path(x,y+1);
  if (!table->get(x,y-1).hard && map[x][y-1]<map[x][y])
    find_path(x,y-1);
}

void DistanceMap::set_path (void) {
  int size=0;

  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++) {
      map[i][j]=path[i][j]?map[i][j]:EMPTY;
      if (map[i][j]!=EMPTY)
        size=path[i][j]?max(size,map[i][j]):size;
    }

  histogram.resize(size+1);

  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++)
      if (path[i][j] && map[i][j]!=EMPTY)
	histogram[map[i][j]].insert(pCellPos(new CellPos(i,j)));

  for (int k=0; k<size; k++)
    if (histogram[k].size()==1) {
      pCellPos cell=*(histogram[k].begin());
      int i=cell->x, j=cell->y;
      pGroup p(new Group(i,j,0,table,Cell::WHITE));
      table->soft.push_back(p);
      table->get(i,j).grouped=true;
      if (table->get(i+1,j).color==Cell::GRAY && !path[i+1][j])
	table->get(i+1,j).color=Cell::BLACK;
      if (table->get(i-1,j).color==Cell::GRAY && !path[i-1][j])
        table->get(i-1,j).color=Cell::BLACK;
      if (table->get(i,j+1).color==Cell::GRAY && !path[i][j+1])
	table->get(i,j+1).color=Cell::BLACK;
      if (table->get(i,j-1).color==Cell::GRAY && !path[i][j-1])
	table->get(i,j-1).color=Cell::BLACK;
      histogram[k].clear();
    }
}

bool DistanceMap::trim(void) {
  bool changed=false;

  for (int j=0; j<sy; j++) 
    for (int i=0; i<sx; i++)
      if (map[i][j]==EMPTY && table->get(i,j).color==Cell::GRAY) {
	table->get(i,j).color=Cell::BLACK;
 	changed=true;
      }
  return changed;
}

// Table (definitions) -------------------------------------------

Table::~Table() {
  //hard.clear();
  //black.clear();
  //soft.clear();
}

Table::Table (Table &t): verbose(t.verbose),extra(t.extra),distance(t.distance) {
  sx=t.sx; sy=t.sy;
  table.resize(boost::extents[sx+2][sy+2]);
  for (int i=0; i<sx+2; i++) {
    table[i][0].color=table[i][sy+1].color=Cell::EDGE;
    table[i][0].hard=table[i][sy+1].hard=true;
  }
  for (int i=0; i<sy+2; i++) {
    table[0][i].color=table[sx+1][i].color=Cell::EDGE;
    table[0][i].hard=table[sx+1][i].hard=true;
  }
  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++){
      get(i,j).grouped=false;
      get(i,j).color=Cell::GRAY;
      get(i,j).hard=false;
      get(i,j).number=t.get(i,j).number;
    }
  init();
  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++) {
      if (t.get(i,j).color==Cell::WHITE && t.get(i,j).number==0)
	insert_soft(i,j);
      if (t.get(i,j).color==Cell::BLACK)
	insert_black(i,j);
    }
  merge_soft();
  merge_black();
  level=t.level+1;
}

Table::Table (int x, int y): level(0),verbose(false),extra(false),distance(false) {
  int i;

  sx=x; sy=y;
  table.resize(boost::extents[sx+2][sy+2]);
  for (i=0; i<x+2; i++) {
    table[i][0].color=table[i][sy+1].color=Cell::EDGE;
    table[i][0].hard=table[i][sy+1].hard=true;
  }
  for (i=0; i<y+2; i++) {
    table[0][i].color=table[sx+1][i].color=Cell::EDGE;
    table[0][i].hard=table[sx+1][i].hard=true;
  }
}

Cell &Table::get (int x, int y) {
  return table[x+1][y+1];
}

Cell &Table::get (pCellPos p) {
  return table[p->x+1][p->y+1];
}

ostream& operator<< (ostream &os, Table &t) {
  int i,j;
  string s;

  for (j=0; j<t.sy; j++) {
    for (i=0; i<t.sx; i++)
      if (t.get(i,j).number>0)
        os<<single_digit(t.get(i,j).number);
      else
        os<<((t.get(i,j).color==Cell::GRAY)?"x":(t.get(i,j).color)==Cell::BLACK?".":"#");
    os << "\n";
  }
  os << "\n";
  if (t.extra) {
    os << "White groups ------------\n";
    BOOST_FOREACH (pGroup g, t.hard)
       os << *g;
    os << "Black groups ------------\n";
    BOOST_FOREACH (pGroup g, t.black)
       os << *g;
    os << "Soft groups ------------\n";
    BOOST_FOREACH (pGroup g, t.soft)
       os << *g;
  }
  return os;
}

void Table::setNumber (int x, int y, int number) {
  get(x,y).color=Cell::WHITE;
  get(x,y).number=number;
}

void Table::merge_black(pGroup p, pGroup q) {
  pGroup g=pGroup(new Group(*p,*q));
  black.push_back(g);
  black.remove(p);
  black.remove(q);
  BOOST_FOREACH (pCellPos p, g->group)
    get(p->x,p->y).group=g;
}

bool Table::merge_black(void) {
  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++) {
      if (get(i,j).color==Cell::BLACK && get(i+1,j).color==Cell::BLACK &&
	  get(i,j).group!=get(i+1,j).group)
      {
	merge_black(get(i,j).group,get(i+1,j).group);
	merge_black();
	return true;
      }

      if (get(i,j).color==Cell::BLACK && get(i,j+1).color==Cell::BLACK &&
	  get(i,j).group!=get(i,j+1).group)
      {
	merge_black(get(i,j).group,get(i,j+1).group);
	merge_black();
	return true;
      }

    }
  return false;
}

bool Table::merge_soft(void) {
  // merge soft with soft
  BOOST_FOREACH (pGroup p,soft)
    BOOST_FOREACH (pGroup q,soft)
      if (p<q)
      BOOST_FOREACH (pCellPos c1, p->group)
	BOOST_FOREACH (pCellPos c2, q->group)
	  if (*c1-*c2==1) {
	      soft.push_back(pGroup(new Group(*p,*q)));
	      soft.remove(p);
	      soft.remove(q);
	      merge_soft();
	      return true;
	  }

  // merge soft with hard
  BOOST_FOREACH (pGroup p,hard)
    BOOST_FOREACH (pGroup q,soft)
      BOOST_FOREACH (pCellPos c1, p->group)
	BOOST_FOREACH (pCellPos c2, q->group)
	  if (*c1-*c2==1) {
	      hard.push_back(pGroup(new Group(*p,*q)));
	      hard.remove(p);
	      soft.remove(q);
	      merge_soft();
	      return true;
	  }
  return false;
}

bool Table::create_black_groups(void) {
  bool changed=false;

  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++)
      if (get(i,j).color==Cell::BLACK && !get(i,j).grouped) {
        pGroup p(new Group(i,j,black_size,this,Cell::BLACK));
        black.push_back(p);
	get(i,j).group=p;
 	changed=true;
      }

  if (changed)
    merge_black();

  return changed;
}

bool Table::extend_groups(list<pGroup> group) {
  bool changed=false;

  BOOST_FOREACH (pGroup p, group)
    p->update_boundaries();

  BOOST_FOREACH (pGroup p, group) {
    if (p->boundary.size()==1)
      if ((p->size==0) || (p->size>0 && p->current<p->size)) {
        pCellPos cell=*(p->boundary.begin());
        p->add(cell);
	get(cell->x,cell->y).group=p;
        changed=true;
      }
  }
  return changed;
}

int Table::count_boundaries(int i,int j, pGroup p) {
  int count=0;
  if (p->is_boundary(i+1,j)) count++;
  if (p->is_boundary(i-1,j)) count++;
  if (p->is_boundary(i,j+1)) count++;
  if (p->is_boundary(i,j-1)) count++;
  return count;
}

void Table::insert_soft (int x, int y) {
  get(x,y).color=Cell::WHITE;
  get(x,y).grouped=true;
  pGroup p(new Group(x,y,0,this,Cell::WHITE));
  soft.push_back(p);
}

void Table::insert_black (int x, int y) {
  get(x,y).color=Cell::BLACK;
  get(x,y).grouped=true;
  pGroup p(new Group(x,y,black_size,this,Cell::BLACK));
  black.push_back(p);
  get(x,y).group=p;
}

void Table::init (void) {
  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++)
      if (get(i,j).number>0) {
        pGroup p(new Group(i,j,get(i,j).number,this,Cell::WHITE));
        hard.push_back(p);
      }
  black_size=0;
  BOOST_FOREACH (pGroup p,hard)
    black_size+=p->size;
  black_size=sx*sy-black_size;
}

int Table::solve (void) {


  vector<pSolution> methods;

  methods.push_back(pSolution(new clear_complete_groups()));
  methods.push_back(pSolution(new clear_shared_cells()));
  methods.push_back(pSolution(new extend_hard_groups()));
  methods.push_back(pSolution(new extend_black_groups()));
  methods.push_back(pSolution(new create_elbow()));
  methods.push_back(pSolution(new tail_implication()));
  methods.push_back(pSolution(new extend_soft_groups()));
  methods.push_back(pSolution(new soft_exceeds_hard()));
  methods.push_back(pSolution(new erase_unreachables()));
  methods.push_back(pSolution(new find_path()));
  methods.push_back(pSolution(new check_bugs()));
  methods.push_back(pSolution(new update_path()));
  methods.push_back(pSolution(new count_reachables()));
  methods.push_back(pSolution(new extend_toward_hard()));
  methods.push_back(pSolution(new block_implication()));
  methods.push_back(pSolution(new limited_growth()));

  sort(methods.begin(),methods.end(),pSolutionCompare);

  try {
    for (vector<pSolution>::iterator it=methods.begin(); it<methods.end(); ) {
      if ((**it).solve(this)) {
        if (verbose && level==0) {
          cout << (**it).name() << '\n';
          cout << *this;
        }
        it=methods.begin();
      } else it++;
    }

    // check if puzzle was solved
    if (finished())
      return SOLVED;

  } catch (BugException bug) {
    return IMPOSSIBLE;
  }

  // exceeded maximum recursion level
  if (level>5)
    return UNSOLVED;

  // search best recursion point
  BOOST_FOREACH (pGroup h, hard)
    h->update_boundaries();
  pGroup chosen=*(hard.begin());
  int choose=(chosen->size-chosen->current)*(signed)chosen->boundary.size();
  BOOST_FOREACH (pGroup h, hard)
    if (choose>(h->size-h->current)*(signed)h->boundary.size()) {
      choose=(h->size-h->current)*(signed)h->boundary.size();
      chosen=h;
    }

  assert (chosen->boundary.size()>0);
  int rx=(**(chosen->boundary.begin())).x;
  int ry=(**(chosen->boundary.begin())).y;

  if (verbose)
    cout << "Recursion level "<<level<<"\n";

  // perform recursion
  Table tw(*this);
  tw.insert_soft(rx,ry);
  tw.merge_soft();
  int tw_result=tw.solve();

  Table tb(*this);
  tb.insert_black(rx,ry);
  tb.merge_black();
  int tb_result=tb.solve();

  // check recursion results
  if (tw_result==IMPOSSIBLE && tb_result==IMPOSSIBLE)
    return IMPOSSIBLE;

  if (tw_result==MULTIPLE || tb_result==MULTIPLE) {
    if (tw_result==SOLVED)
      cout << tw;
    if (tb_result==SOLVED)
      cout << tb;
    return MULTIPLE;
  }

  if (tw_result==SOLVED && tb_result==SOLVED) {
    cout << tw;
    cout << tb;
    return MULTIPLE;
  }

  if (tw_result==SOLVED) {
    table=tw.table;
    return SOLVED;
  }
  if (tb_result==SOLVED) {
    table=tb.table;
    return SOLVED;
  }
  return UNSOLVED;
}

bool Table::finished(void) {
  for (int i=0; i<sx; i++)
    for (int j=0; j<sy; j++)
      if (get(i,j).color==Cell::GRAY)
	return false;

  if (soft.size()>0)
    throw bug;
  if (hard.size()>0)
    throw bug;
  if (black.size()!=1)
    throw bug;
  BOOST_FOREACH (pGroup p, black)
    if (p->size!=p->current)
      throw bug;

  return true;
}

void Table::update_hard(void) {
  BOOST_FOREACH(pGroup p,hard)
    BOOST_FOREACH(pCellPos c,p->group)
      get(c).hard=true;

  BOOST_FOREACH(pGroup p,black)
    BOOST_FOREACH(pCellPos c,p->group)
      get(c).hard=true;
}

// main ----------------------------------------------------------

int main (int argc, char **argv) {
  Table *t;
  int x,y,m,i,n,c;
  bool verbose=false, extra=false, distance=false;

  while ((c=getopt(argc,argv,"vxd"))!=-1) {
    switch (c) {
      case 'v': verbose=true; break;
      case 'x': extra=true; break;
      case 'd': distance=true; break;
    }
  }

  cin>>x; cin>>y;
  t=new Table(x,y);
  cin>>m;
  for (i=0; i<m; i++) {
    cin >>x; cin >>y; cin >>n;
    t->setNumber(x,y,n);
  }
  t->verbose=verbose;
  t->extra=extra;
  t->distance=distance;
  t->init();
  switch (t->solve()) {
    case Table::SOLVED:
      cout << "Solved\n";
      break;
    case Table::UNSOLVED:
      cout << "Unsolved\n";
      break;
    case Table::IMPOSSIBLE:
      cout << "Impossible\n";
      break;
    case Table::MULTIPLE:
      cout << "Multiple solutions\n";
      break;
  }
  cout <<*t;
  delete t;
  return 0;
}
