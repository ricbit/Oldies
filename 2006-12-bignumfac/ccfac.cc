#include <stdio.h>

char prec[100][166];

typedef const static int csint;

template<int digit, int n>
struct fac {
  csint value=fac<digit,n-1>::value%10000*n+(fac<digit-1,n>::value/10000);
};

template<int digit>
struct fac<digit,0> {
  csint value=0;
};

template<int n>
struct fac<-1,n> {
  csint value=0;
};

template<>
struct fac<0,0> {
  csint value=1;
};

#define K(a) prec[n][163-digit*4-a]

template<int digit, int n>
struct select {
  csint d=fac<digit,n>::value%10000;
  static inline void print(void) {
    K(0)=d%10+'0'; 
    K(1)=d/10%10+'0';
    K(2)=d/100%10+'0';
    K(3)=d/1000%10+'0';
    select<digit-1,n>::print();
  }
};

template<int n>
struct select<-1,n> {
  csint d=0;
  static inline void print(void) { prec[164][n]='\n'; prec[165][n]=0; }
};

#define D(x) select<40,x>::print

typedef void (*f)();

f p[101]={
D(0),D(1),D(2),D(3),D(4),D(5),D(6),D(7),D(8),D(9),D(10),D(11),D(12),D(13),D(14),D(15),D(16),D(17),D(18),D(19),D(20)
,D(21),D(22),D(23),D(24),D(25),D(26),D(27),D(28),D(29),D(30),D(31),D(32),D(33),D(34),D(35),D(36),D(37),D(38),D(39),D(40),D(41),D(42),D(43),D(44),D(45),D(46),D(47),D(48),D(49),D(50),D(51),D(52),D(53),D(54),D(55),D(56),D(57),D(58),D(59),D(60),D(61),D(62),D(63),D(64),D(65),D(66),D(67),D(68),D(69),D(70),D(71),D(72),D(73),D(74),D(75),D(76),D(77),D(78),D(79),D(80),D(81),D(82),D(83),D(84),D(85),D(86),D(87),D(88),D(89),D(90),D(91),D(92),D(93),D(94),D(95),D(96),D(97),D(98),D(99),D(100)
};

int main (void) {
  int tot;
  scanf ("%d",&tot);
  while (tot--) {
    int n;
    scanf ("%d",&n);
    p[n]();
    char *p=prec[n];
    while (*p=='0') p++;
    puts (p);
  }
  return 0;
}
 

