#include "cwa.h"
#include<fstream.h>

//Global variables
extern char LASTFILE[30];
extern int NUMRESLIST;
extern int RESNUM;
extern char LASTRESULT[30];

char userinput[30];

//Global functions used in module
extern char* strprompt(char*);
extern char pause(char*);

//Other functions
void checkword();
void dispabout();
void confirmexit();
void displaylast();
void getcommand(char);
void help();

//For menus
char *mainmenu[]={"Grid","Search","Edit","Results", "Help","Quit"};
char *gridmenu[]={"New","Open","Save","Edit","Print"};
char *searchmenu[]={"Search","Filter","Check word"};
char *helpmenu[]={"Contents","About CWA"};
int mmni=6, gmni=5,smni=3, hmni=2;
char c[6][2];

//Main program

//Objects

Menu MainMenu(mainmenu,mmni,"Main Menu");   //Menu Objects
Menu GridMenu(gridmenu,gmni,"Grid Menu");
Menu SearchMenu(searchmenu,smni,"Search Menu");
Menu HelpMenu(helpmenu,hmni,"Help Menu");

extern searchclass Search;
extern ResList reslist;
gridclass grid(10);

void checkword()
{
 strcpy(userinput, strprompt("WORD TO CHECK: "));
 if(Search.wsearch(userinput,0))
  pause(strcat(::userinput," found in dictionary."));
 else
  pause(strcat(::userinput," - word not found."));
}

void dispabout()
{
   Box about;
   about.setsize(53,8,21,8);
   about.settitle("About CWA");
   savetext(); about.draw();
   _setcursortype(_NOCURSOR);
   about.setitem("Crossword Assistant"); about.boxpos++;
   about.setitem("Version 1.0 For DOS"); about.boxpos++;
   about.setitem("Developed by");        about.boxpos++;
   about.setitem("       Thomas Jacob"); about.boxpos++;
   about.setitem("       & Syam Kumar"); about.boxpos++;
   about.setitem("R-5, TKMCE, Kollam"); about.boxpos++;
   getch();
   about.undraw();
   _setcursortype(_NORMALCURSOR);
}

void confirmexit()
{
 if(toupper(pause("Quit CWA <Y/N>? "))=='Y')
  {
   clrscr();
   flushall();
   exit(0);
  }
}

void displaylast()
 {
  if(streql(LASTFILE,"NULL"))
   pause("No results to display!");
  else
   { reslist.getitems(RESNUM,LASTFILE);
     strcpy(LASTRESULT,reslist.operate());
   }
}

void helpsrch()
{
 Box helper;
 helper.setsize(MENUPOSX,1,25,21);
 helper.draw();
 helper.setitem("INSTRUCTIONS-          "); helper.boxpos++;
 helper.setitem("Enter the search string"); helper.boxpos++;
 helper.setitem("and append a special   "); helper.boxpos++;
 helper.setitem("character to choose an "); helper.boxpos++;
 helper.setitem("operation."); helper.boxpos++;
 helper.setitem("                       "); helper.boxpos++;
 helper.setitem("CHAR        OPERATION  "); helper.boxpos++;
 helper.setitem("                       "); helper.boxpos++;
 helper.setitem(" *          Anagrammer "); helper.boxpos++;
 helper.setitem(" %          LetterSet  "); helper.boxpos++;
 helper.setitem(" #          Substring  "); helper.boxpos++;
 helper.setitem(" *          Any Of Set "); helper.boxpos++;
 helper.setitem("                       "); helper.boxpos++;
 helper.setitem(" Add ! for complement."); helper.boxpos++;
 helper.setitem(" Add | for filter      "); helper.boxpos++;
 helper.setitem("                       "); helper.boxpos++;
 helper.setitem("Press ENTER after      "); helper.boxpos++;
 helper.setitem("typing command.        "); helper.boxpos++;
 helper.deactivate();
}

void getcommand(char c)
{
 char choice[2];

 helpsrch();
 strcpy(::userinput, strprompt("ENTER COMMAND: "));
 if(c=='F') strcat(userinput,"|");
 Box helper; helper.setsize(MENUPOSX,1,25,21); helper.undraw();
 window(1,1,80,25);

 if(Search.wsearch(userinput,0)) displaylast();
 else pause("Found no matches.");

}

void help()
{
 int i,j;
 char fn[8],temp[80];

 savetext();
 textbackground(BGColor); textcolor(FGColor);
 for(i=1;i<=3;i++)
  {
   clrscr();
   strcpy(fn,"help.");
   itoa(i,temp,10);
   strcat(fn,temp);
   ifstream hf(fn,ios::in);
   if(hf)
    {
     for(j=1;j<=20;j++)
       {
	gotoxy(1,j);
	hf.getline(temp,80);
	cout<<temp;
       }
     hf.close();
     cout<<"\n\nPress any key to continue.";
     getch();
    }
  }
 restoretext();
}

//Driver program

void main()
{
 int n;

 textbackground(BGColor); textcolor(FGColor);
 clrscr();
 grid.drawgrid();

 do
   {
    strncpy(c[0],MainMenu.operate(),2);
    switch(c[0][0])
    {
     case 'G':
      strncpy(c[1],GridMenu.operate(),2);
       switch(c[1][0])
	{
	 case 'N': grid.newgrid();     break;
	 case 'O': grid.load();    break;
	 case 'S': grid.save();    break;
	 case 'E': grid.operate(); break;
	 case 'P': grid.print(); break;
	}
      break;

     case 'S':
      strncpy(c[2],SearchMenu.operate(),2);
       switch(c[2][0])
	{
	 case 'F':
	 case 'S': getcommand(c[2][0]);break;
	 case 'C': checkword(); break;
	}
      break;

     case 'E':     grid.operate(); break;
     case 'R':	   displaylast();  break;
     case 'H':
      strncpy(c[5],HelpMenu.operate(),2);
       switch(c[5][0])
	{
	 case 'A': dispabout();
		   break;
	 case 'C': help();
		   break;
	}
      break;

     case ' ': c[0][0]='Q';
     case 'Q': confirmexit();
	       c[0][0]=' ';
	       break;
    }
   }while(c[0][0]!='Q');
}


