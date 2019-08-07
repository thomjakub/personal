//Project header
//Contains class/constant declarations

#include<conio.h>
#include<string.h>
#include<ctype.h>
#include<stdlib.h>
#include<iostream.h>
#include<stdio.h>
#include "keys.h"

#define MENUPOSX 53

//cursor directions for movecursor()
#define RIGHT 0
#define LEFT 2
#define UP 3
#define DOWN 1

//For symmetry, 0 for no symmetry
#define NONE 0
#define TWOWAY 1
#define FOURWAY 2

#define BGColor BLACK
#define FGColor LIGHTGRAY

#define MAXITEMS 100

//BOX

#define OK 1
#define OFF 0
#define ON 1

class Box
   {
   protected:
      // box configuration parameters
      int uleftx, ulefty, boxw, boxht;
      int fgcolor, bgcolor;
      char *title;

   public:
      int boxpos; //row in box
      Box();     // constructor with no args.
      void setsize(int ulx, int uly, int bw, int bh);
      void setcolor(int fgc, int bgc);
      void settitle(char *txt);
      void activate();
      void deactivate();
      void setitem(char *s);
      int draw();
      void undraw();
   };

class Menu : public Box
{
 private:
  virtual void movebar(int mode);

 protected:
  char **itemtext;
  int n,maxitemlen,start,listsize;
  int menurow;
  char *hotkeys;

  void highlight();
  void menubar();
  void writeitemlist();

 public:
  int hkeys;
  Menu(char *s[], int ,char *); //Constructor for normal menu
  Menu();
  ~Menu();
  char* operate();

};


//RESULT LIST
class ResList : public Menu
{
 private:
  FILE* resfile;
 protected:
  void movebar(int);

 public:
  ResList();
  ResList(char **, int,int );
  void getitems(int,char *);
  void freemem();
  ~ResList();
};

//SEARCH CLASS
#define FILTER 0
#define NEW 1

#define FINDWORD 0
#define ANAGRAM 1
#define LETSET 2
#define MATCHSTR 3
#define ANYSET 4

class searchclass
{
 protected:
  int iteration, invflag, opcode, wlen;
  long numfound;
  char ifname[30], ofname[30];
  char *workstr;
  FILE *ifile,*ofile;
  int status;

 private:
  char* condition(char*);
  long checksum(char*);

 public:
  searchclass();
  ~searchclass();
  int wsearch(char *rawstr,int);
  int openfiles();
  int search(int);
};

#define MUP 0
#define MDOWN 1

//GENERAL FUNCTIONS
/*Global variables*/

extern void far *tbuffer;     //save screen etc

extern void savetext();
extern void restoretext();
extern int scan();
extern void swap(int&,int&);
extern void blkbox(int);
extern char pause(char*);
extern char* strprompt(char*);
extern int streql(char*,char*);
extern void strtrim(char*);

//GRID
class gridclass
{
 protected:
  int size;
  int crow,ccol; //where are we in the grid?
  struct
   {
    char value;
   } cell[16][16];

 public:
  int cluebegrow,cluebegcol,cluelen;
  char clue[16];

 private:
   int convrow(int);
   int convcol(int);

  public:
   gridclass(int);
   void init();
   void fillcell();
   void fillcell(int,int);
   void fillgrid();
   void drawgrid();
   void operate();
   void setvalue(char);
   void movecursor(int);
   void helpscrn();
   int save();
   int load();
   int iscluestart(int);
   char* getclue();
   void solvecur();
   void intellimove();
   char nextcell(int);
   int nextcurpos(int);
   int insert(char*);
   void reset();
   void statusline();
   void newgrid();
   void print();
};

