// BOSS 1.0
// by Ricardo Bittencourt 1996
// header ERROR

#ifndef __ERROR_H
#define __ERROR_H

enum errortype {
  ERROR_FATAL,
  ERROR_RETRY
};

enum actiontype {
  ACTION_ABORT,
  ACTION_RETRY,
  ACTION_IGNORE
};

void InstallErrorHandler (void);
actiontype ReportError (errortype id, char *error);

#endif

