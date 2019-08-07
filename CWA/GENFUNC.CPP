//GENFUNC
//Miscellaneous functions

#include"cwa.h"

//For saving screen
void far* tbuffer;

void savetext()
 { tbuffer=new char[4000]; gettext(1,1,80,25,tbuffer); }

void restoretext()
 { puttext(1,1,80,25,tbuffer); delete tbuffer;}

int scan() //returns scan code of key pressed
{
 int i,c;

 c=getch();
 if(c==0)
  {
   c=getch();
   c=-c;
  }
 return(c);
}

void swap(int& a,int& b )
{
 int temp;
 temp=a;
 a=b;
 b=temp;
}

void blkbox(int row)
{
 for(int i=1;i<=79;i++)
  {
   if(row-1>=1) {gotoxy (i,row-1);  cout<<char(SBLOCK);}
   if(row+1<=25) {gotoxy (i,row+1); cout<<char(SBLOCK);}
  }
}

char pause(char *prompt="")
{
 int ty,tx;
 char c;

 ty=wherey(); tx=wherex(); savetext();
 textbackground(BGColor); textcolor(FGColor);
 blkbox(24); gotoxy(1,24); clreol();
 cout<<prompt; c=getche();
 restoretext(); gotoxy(tx,ty);
 return(c);
}

char *strprompt(char *prompt="Input: ")
{
 int i=0;
 char c;
 char *t=new char[80];

 savetext();
 textbackground(BGColor); textcolor(FGColor);
 window(1,1,80,25);
 blkbox(24);
 gotoxy(1,24);
 clreol();
 cout<<prompt;

 do
 {
  c=toupper(getch());
  if( (wherex()<70 && c!=ENTERKEY) || (wherex()>=70 && c==BKSPKEY) )
   {
    if(isalpha(c) || isdigit(c))
      { cout<<c;  t[i++]=c; }
    else
    {
      switch(c)
      {
       case '%':
       case '*':
       case '#':
       case '!':
       case '|':
       case ':':
       case '.':
       case '\\':
       case '?':
       case '=':
		cout<<c;
		t[i++]=c;
		break;
       case BKSPKEY:
		if(wherex()>1)
		 {
		  gotoxy(wherex()-1,24);
		  cout<<" \b";
		  t[--i]='\0';
		 }
		break;
      }
     }
   }
 }while(c!=ENTERKEY);
 t[i]='\0';

 restoretext();
 return(t);
}

int streql(char*a,char*b)
{
 if(strcmpi(a,b)) return(0);
 return(1);
}

void strtrim(char *t)
{
 int i;
 i=strlen(t)-1;
 while(t[i]==' ' && i>=0)
  t[i--]='\0';
}

