#include "cwa.h"

extern char LASTFILE[30];
extern long RESNUM;
extern char LASTRESULT[30];

Menu::Menu(char *s[], int nm,char *mtitle) //Constructor for normal menu
 {
     n=nm;        //Store actual number of items in object
     listsize=n;  //Number of rows in box
     itemtext=new char* [nm];
     hotkeys=new char[nm+1];
     maxitemlen=strlen(mtitle);
     settitle(mtitle);

     menurow=1;start=0;hkeys=1;

     for(int i=0;i<n;i++)
      {
       itemtext[i]=s[i];
       strcpy(itemtext[i],s[i]);
       if(strlen(itemtext[i])>maxitemlen) maxitemlen=strlen(itemtext[i]);
       hotkeys[i]=itemtext[i][0];
      }
     hotkeys[n]='\0';

     boxw=maxitemlen+5;
     boxht=n+2;
 }

Menu::Menu() //Required for inheriting
{
}

Menu::~Menu()
 {  delete itemtext; }

void Menu::highlight()
 {
  int temp=boxpos;
  swap(bgcolor,fgcolor);
  boxpos=menurow;
  setitem(itemtext[start+menurow-1]);
  swap(bgcolor,fgcolor);
  boxpos=temp;
   }

void Menu::menubar()
  {
   gotoxy(1,menurow);
   highlight();
  }

void Menu::writeitemlist()
 {
   activate();
   boxpos=1;
   for(int i=start;i<start+listsize;i++)
    {setitem(itemtext[i]);
     boxpos++;}
 }

void Menu::movebar(int mode)
 {
  switch(mode)
   {case MUP: 	menurow=(menurow-1)%(n+1);
		if(menurow==0) menurow=n;
		break;
    case MDOWN: menurow=(menurow+1)%(n+1);
		if(menurow==0) menurow=1;
		break;
   }
  writeitemlist();
  highlight();
 }


char* Menu::operate()
 {
  char mchoice[2];
  int temp;

  mchoice[1]='\0';

  savetext();
  _setcursortype(_NOCURSOR);
  setsize(53,(24-(listsize+2))/2+1,boxw,boxht);
  draw();
  writeitemlist();
  do
   {
    menubar();
    mchoice[0]=toupper(scan());
    if(hkeys)
    if(strstr(hotkeys,mchoice))
     {
      deactivate();
      restoretext();
      _setcursortype(_NORMALCURSOR);
      return(mchoice);
      }

    switch(mchoice[0])
    {
     case LEFTKEY:
     case UPKEY:	movebar(MUP);
			break;
     case RIGHTKEY:
     case DOWNKEY:	movebar(MDOWN);
			break;
     case ENTERKEY:     deactivate();
			restoretext();
			_setcursortype(_NORMALCURSOR);
			return(itemtext[start+menurow-1]);
     case PGUPKEY:
			if(n==listsize) break;
			if((start-listsize)>=0) start-=listsize;
			else start=0;
			writeitemlist();
			menubar();
			break;
     case PGDNKEY:
			if(n==listsize) break;
			if((start+listsize)<=n-listsize) start+=listsize-1;
			else start=n-listsize;
			writeitemlist();
			menubar();
			break;
    }
  }while(mchoice[0]!=ESCKEY);
  deactivate();
  restoretext();
  _setcursortype(_NORMALCURSOR);
  return(" ");
}

