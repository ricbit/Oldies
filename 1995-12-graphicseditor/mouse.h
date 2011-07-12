#ifndef _MOUSE_H
#define _MOUSE_H

#ifdef __cplusplus
extern "C" {
#endif

class Mouse {
public:
  int x,y;

  Mouse (void);
  void Read (void);
  int Left (void);
  int Right (void);
};

#ifdef __cplusplus
}
#endif

#endif