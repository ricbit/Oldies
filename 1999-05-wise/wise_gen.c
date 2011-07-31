#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>

#define SAFE_VALUE 64

void my_strupr (char *p) {
  while (*p=*p>='a'&&*p<='z'?*p-'a'+'A':*p,*++p);
}

void *safe_malloc (int size) {
  return malloc (size<SAFE_VALUE?SAFE_VALUE:size);
}

