// Video.h

#ifndef kVideo
#define kVideo

#include "Compiler.h"
#include "YoMath.h"

typedef unsigned char byte_;
typedef unsigned int word;
typedef unsigned long dword;

class Cor {
public:
  byte_ c[3];

  // Constructor
  Cor ();
  Cor (Vetor v);
};

typedef Cor Palette[256];

class Video {
public:
  int
    MaxX,		//Maior coordenada X
    MaxY;		//Maior coordenada Y
  int maxpal;
  Palette pal;

  //Constructor
  Video ();

  //Inicializa o modo grafico
  void Init ();

  //Fecha o modo grafico
  void Close ();

  //Coloca um ponto de cor c na posicao (x,y) da tela
  virtual void Point (int x, int y, byte_ cor);

  //Seta uma cor n da palette em (r,g,b)
  void SetRGB (byte_ n, byte_ r, byte_ g, byte_ b);

  //Traca uma linha de cor c da posicao (x1,y1) a posicao (x2,y2)
  void Line (int x1, int y1, int x2, int y2, int cor);

  //Traca um retangulo de cor c com vertices (x1,y1) e (x2,y2)
  void Rectangle (int x1, int y1, int x2, int y2, int cor);

  //Traca um retangulo preeenchido com a cor c de vertices (x1,y1)-(x2,y2)
  void Bar (int x1, int y1, int x2, int y2, int cor);

  //Coloca uma linha de n byte_s na posicao y da tela
  void CopyLine (int n, int y, byte_ far *line);

  //Insere uma cor na palette
  byte_ Inclui (Cor c);

  //Espera por uma tecla
  void WaitForKey (void);

  //Verifica se uma tecla foi apertada
  int KeyPressed (void);

};

#endif
