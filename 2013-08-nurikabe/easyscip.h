// EasySCIP 0.1
// A C++ interface to SCIP that is easy to use.
// by Ricardo Bittencourt 2013

// Please check the examples for a sample usage.

#include <vector>
#include "objscip/objscip.h"
#include "objscip/objscipdefplugins.h"

namespace easyscip {

class Constraint;
class MIPConstraint;
class CutConstraint;
class Solution;
class MIPSolution;
class LPSolution;
class MIPSolver;
class Handler;
class DynamicConstraint;

class Variable {
 protected:
  Variable() : var_(NULL) {
  }
  SCIP_VAR *var_;
  friend Constraint;
  friend MIPConstraint;
  friend CutConstraint;
  friend Solution;
  friend MIPSolution;
  friend LPSolution;
  friend MIPSolver;
};

class BinaryVariable : public Variable {
 protected:
  BinaryVariable(SCIP *scip, double objective) {
    SCIPcreateVarBasic(
        scip, &var_, "variable", 0, 1, objective, SCIP_VARTYPE_BINARY);
    SCIPaddVar(scip, var_);
  }
  friend MIPSolver;
};

class IntegerVariable : public Variable {
 protected:
  IntegerVariable(SCIP *scip, double lower_bound, double upper_bound, 
                  double objective) {
    SCIPcreateVarBasic(
        scip, &var_, "variable", lower_bound, upper_bound, objective, 
        SCIP_VARTYPE_INTEGER);
    SCIPaddVar(scip, var_);
  }
  friend MIPSolver;
};

class BaseConstraint {
 public:
  virtual void add_variable(Variable& var, double val) = 0;
  virtual void commit(double lower_bound, double upper_bound) = 0;
  virtual ~BaseConstraint() {
  }
};

class Constraint {
 public:
  void add_variable(Variable& var, double val) {
    constraint_->add_variable(var, val);
  }
  void commit(double lower_bound, double upper_bound) {
    constraint_->commit(lower_bound, upper_bound);
  }
  ~Constraint() {
    delete constraint_;
  }
 private:
  Constraint(BaseConstraint *constraint) : constraint_(constraint) {
  }
  BaseConstraint *constraint_;
  friend MIPSolver;
  friend DynamicConstraint;
};

class EmptyConstraint : public BaseConstraint {
 public:
  virtual void add_variable(Variable& var, double val) {
  }
  virtual void commit(double lower_bound, double upper_bound) {
  }
};

class MIPConstraint : public BaseConstraint {
 public:
  virtual void add_variable(Variable& var, double val) {
    vars_.push_back(var.var_);
    vals_.push_back(val);
  }
  virtual void commit(double lower_bound, double upper_bound) {
    SCIP_VAR **vars = new SCIP_VAR*[vars_.size()];
    SCIP_Real *vals = new SCIP_Real[vals_.size()];
    copy(vars_.begin(), vars_.end(), vars);
    copy(vals_.begin(), vals_.end(), vals);
    SCIP_CONS *cons;
    SCIPcreateConsLinear(
        scip_, &cons, "constraint", vars_.size(), vars, vals, 
        lower_bound, upper_bound, 
        TRUE,   // initial
        TRUE,   // separate
        TRUE,   // enforce
        TRUE,   // check
        TRUE,   // propagate
        FALSE,  // local
        FALSE,  // modifiable
        FALSE,  // dynamic
        FALSE,  // removable
        FALSE); // stickatnode
    //printf("add: %d\n", SCIPaddCons(scip_, cons));
    SCIPaddCons(scip_, cons);
    SCIPreleaseCons(scip_, &cons);
    delete[] vars;
    delete[] vals;
  }
 private:
  SCIP *scip_;
  std::vector<SCIP_VAR*> vars_;
  std::vector<SCIP_Real> vals_;
  MIPConstraint(SCIP *scip) : scip_(scip) {
  }
  friend MIPSolver;
  friend DynamicConstraint;
};

class CutConstraint : public BaseConstraint {
 public:
  virtual void add_variable(Variable& var, double val) {
    vars_.push_back(var.var_);
    vals_.push_back(val);
  }
  virtual void commit(double lower_bound, double upper_bound) {
    SCIP_ROW *row;
    SCIPcreateEmptyRowCons(scip_, &row, handler_, "cut", lower_bound, upper_bound, FALSE, FALSE, FALSE);
    SCIPcacheRowExtensions(scip_, row);
    for (int i = 0; i < int(vars_.size()); i++) {
      SCIPaddVarToRow(scip_, row, vars_[i], vals_[i]);      
    }
    SCIPflushRowExtensions(scip_, row);
    if (SCIPisCutEfficacious(scip_, NULL, row)) {
      //printf("added cut\n");
      SCIPaddCut(scip_, NULL, row, FALSE);
      SCIPaddPoolCut(scip_, row);
    } //else {
      //printf("skipped cut\n");

    //}
    SCIPreleaseRow(scip_, &row);
    // old
    /*SCIP_VAR **vars = new SCIP_VAR*[vars_.size()];
    SCIP_Real *vals = new SCIP_Real[vals_.size()];
    copy(vars_.begin(), vars_.end(), vars);
    copy(vals_.begin(), vals_.end(), vals);
    SCIP_CONS *cons;
    SCIPcreateConsLinear(
        scip_, &cons, "constraint", vars_.size(), vars, vals, 
        lower_bound, upper_bound, 
        TRUE,   // initial
        TRUE,   // separate
        TRUE,   // enforce
        TRUE,   // check
        TRUE,   // propagate
        FALSE,  // local
        FALSE,  // modifiable
        FALSE,  // dynamic
        FALSE,  // removable
        FALSE); // stickatnode
    //printf("add: %d\n", SCIPaddCons(scip_, cons));
    SCIPaddCons(scip_, cons);
    SCIPreleaseCons(scip_, &cons);
    delete[] vars;
    delete[] vals;*/
  }
 private:
  SCIP *scip_;
  SCIP_CONSHDLR *handler_;
  std::vector<SCIP_VAR*> vars_;
  std::vector<SCIP_Real> vals_;
  CutConstraint(SCIP *scip) : scip_(scip), handler_(SCIPfindConshdlr(scip, "group")) {
  }
  friend MIPSolver;
  friend DynamicConstraint;
};

class BaseSolution {
 public:
  virtual double objective() = 0;
  virtual double value(Variable& var) = 0;
  virtual bool is_optimal() = 0;
  virtual ~BaseSolution() {
  }
};

class Solution {
 public:
  double objective() const {
    return solution_->objective();
  }
  double value(Variable& var) const {
    return solution_->value(var);
  }
  bool is_optimal() const {
    return solution_->is_optimal();
  }
  ~Solution() {
    delete solution_;
  }
 private:
  Solution(BaseSolution *solution) : solution_(solution) {
  }
  BaseSolution *solution_;
  friend MIPSolver;
  friend Handler;
};

class MIPSolution : public BaseSolution {
 public:
  virtual double objective() {
    return SCIPgetSolOrigObj(scip_, sol_);
  }
  virtual double value(Variable& var) {
    return SCIPgetSolVal(scip_, sol_, var.var_);
  }
  virtual bool is_optimal() {
    return SCIPgetStatus(scip_) == SCIP_STATUS_OPTIMAL;
  }
 private:
  MIPSolution(SCIP *scip, SCIP_Sol *sol) : scip_(scip), sol_(sol) {
  }
  virtual ~MIPSolution() {
  }
  SCIP *scip_;
  SCIP_Sol *sol_;
  friend MIPSolver;
  friend Handler;
};

class LPSolution : public BaseSolution {
 public:
  virtual double objective() {
    return 0;
  }
  virtual double value(Variable& var) {
    return SCIPgetVarSol(scip_, var.var_);
  }
  virtual bool is_optimal() {
    return SCIPgetStatus(scip_) == SCIP_STATUS_OPTIMAL;
  }
 private:
  LPSolution(SCIP *scip) : scip_(scip) {
  }
  virtual ~LPSolution() {
  }
  SCIP *scip_;
  friend Handler;
};

class DynamicConstraint {
 public:
  virtual bool check_solution(Solution& solution) = 0;
  Constraint constraint() {
    if (enable_) {
      return Constraint(new CutConstraint(scip_));
    } else {
      return Constraint(new EmptyConstraint());
    }
  }
 protected:
  DynamicConstraint() : enable_(false), scip_(NULL) {
  }
 private:
  void set_constraint(bool enable) {
    enable_ = enable;
  }
  void set_scip(SCIP* scip) {
    scip_ = scip;
  }
  bool enable_;
  SCIP* scip_;
  SCIP_CONSHDLR *handler_;
  friend MIPSolver;
  friend Handler;
};

struct Handler : public scip::ObjConshdlr {
  SCIP *scip;
  std::vector<DynamicConstraint*> handlers;
  Handler(SCIP *scip_) 
      : ObjConshdlr(scip_, "group", "group constraint",
                    -10000,      // sepapriority
                    -2000,      // enfopriority
                    -2000,      // checkpriority
                    1,         // sepafreq
                    1,         // propfreq
                    1,          // eagerfreq
                    0,          // maxprerounds
                    TRUE,      // delaysepa
                    FALSE,      // delayprop
                    FALSE,      // delaypresol
                    FALSE,      // needscons
                    SCIP_PROPTIMING_BEFORELP),
        scip(scip_) {
  }
  virtual ~Handler() {
  }
  virtual SCIP_DECL_CONSTRANS(scip_trans) {
    return SCIP_OKAY;
  }
  virtual SCIP_DECL_CONSENFOLP(scip_enfolp) {
    //printf("folp\n");
    Solution solution(new LPSolution(scip));
    *result = SCIP_FEASIBLE;
    for (int i = 0; i < int(handlers.size()); i++) {
      handlers[i]->set_constraint(false);
      if (!handlers[i]->check_solution(solution)) {
        *result = SCIP_INFEASIBLE;
      }
    }
    return SCIP_OKAY;
  }
  virtual SCIP_DECL_CONSSEPALP(scip_sepalp) {
    //printf("sepalp\n");
    Solution solution(new LPSolution(scip));
    *result = SCIP_DIDNOTFIND;
    for (int i = 0; i < int(handlers.size()); i++) {
      handlers[i]->set_constraint(true);
      if (!handlers[i]->check_solution(solution)) {
        *result = SCIP_SEPARATED;
      }
    }
    return SCIP_OKAY;
  }
  virtual SCIP_DECL_CONSENFOPS(scip_enfops) {
    //printf("fops\n");
    *result = SCIP_FEASIBLE;
    return SCIP_OKAY;
  }
  virtual SCIP_DECL_CONSCHECK(scip_check) {
    //printf("check\n");    
    //printf("status %d\n",  SCIPgetStatus(scip_));
    Solution solution(new MIPSolution(scip, sol));
    for (int i = 0; i < int(handlers.size()); i++) {
      handlers[i]->set_constraint(false);
      if (!handlers[i]->check_solution(solution)) {
        *result = SCIP_INFEASIBLE;
        return SCIP_OKAY;
      }
    }
    *result = SCIP_FEASIBLE;
    return SCIP_OKAY;
  }
  virtual SCIP_DECL_CONSLOCK(scip_lock) {
    return SCIP_OKAY;
  }
  void add_dynamic_constraint(DynamicConstraint& constraint) {
    handlers.push_back(&constraint);
  }
};

class MIPSolver {
 public:
  MIPSolver() {
    SCIPcreate (&scip_);
    SCIPsetMessagehdlrLogfile(scip_, "log.txt");
    SCIPprintVersion(scip_, NULL);
    SCIPsetEmphasis(scip_, SCIP_PARAMEMPHASIS_OPTIMALITY, FALSE);
    handler = new Handler(scip_);
    SCIPincludeObjConshdlr(scip_, handler, TRUE);
    SCIPincludeDefaultPlugins(scip_);
    SCIPcreateProbBasic(scip_, "MIP");
  }
  ~MIPSolver() {
    SCIPfree(&scip_);
  }
  Variable binary_variable(double objective) {
    return BinaryVariable(scip_, objective);
  }
  Variable integer_variable(int lower_bound, int upper_bound, 
                            double objective) {
    return IntegerVariable(scip_, lower_bound, upper_bound, objective);
  }
  Constraint constraint() {
    return Constraint(new MIPConstraint(scip_));
  }
  Solution solve() {
    SCIPsolve(scip_);
    return Solution(new MIPSolution(scip_, SCIPgetBestSol(scip_)));
  }
  void add_dynamic_constraint(DynamicConstraint& constraint) {
    constraint.set_scip(scip_);
    handler->add_dynamic_constraint(constraint);
  }
  void set_time_limit(int seconds) {
    SCIPsetRealParam(scip_, "limits/time", seconds);
  }
  int count_solutions() {
    SCIPcount(scip_);
    SCIP_Bool valid;
    return SCIPgetNCountedSols(scip_, &valid);
  }
 private:
  SCIP *scip_;
  Handler *handler;
};

}  // namespace easyscip
