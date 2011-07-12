#include "Menu.h"

void main (void) {
  Menu M;
  M.AddTitle ("Menu do Ricardo");
  M+="Opcao 1";
  M+="Opcao 2";
  M+="Opcao 3";
  M+="Opcao 4";
  switch (M.Exec (10)) {
    case MenuOk: cout << "Menu retornou Ok\n"; break;
    case MenuEsc: cout << "Voce apertou ESC\n"; break;
    case MenuEmpty: cout << "O menu esta vazio\n"; break;
  }
}