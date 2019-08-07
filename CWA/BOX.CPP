#include"cwa.h"

Box::Box()     // constructor with no args.
 {
   title=new char[30];

   uleftx=1; ulefty=1; boxw=80; boxht=25;
   fgcolor=FGColor; bgcolor = BGColor;
   title="";
   boxpos=1;
 }

void Box::setsize(int ulx, int uly, int bw, int bh)
	 { uleftx=ulx; ulefty=uly; boxw=bw; boxht=bh;}

void Box::setcolor(int fgc, int bgc)
	 { fgcolor=fgc; bgcolor=bgc;}

void Box::settitle(char *txt)
	 { title=txt; }

int Box::draw()
  {
   struct text_info t_info;

   // draw the actual window and clear it with bgcolor.
   window(uleftx,ulefty,uleftx+boxw-1,ulefty+boxht-1);
   textbackground(bgcolor);
   clrscr();

   // take off scroll feature.
   _wscroll=OFF;

   //Draw border
   window(1,1,80,25);
   textcolor(fgcolor);
   gotoxy(uleftx,ulefty);  	   		cprintf("%c", TLFTCNR);
   gotoxy(uleftx+boxw-1,ulefty);   		cprintf("%c", TRGTCNR);
   gotoxy(uleftx+boxw-1,ulefty+boxht-1);        cprintf("%c", BRGTCNR);
   gotoxy(uleftx,ulefty+boxht-1);               cprintf("%c", BLFTCNR);

   for (int pos = uleftx + 1; pos<uleftx + boxw-1; pos++)
      {
       gotoxy(pos,ulefty); 		        cprintf("%c", HLEN);
       gotoxy(pos, ulefty + boxht -1 );         cprintf("%c", HLEN);
      }

   for (pos = ulefty + 1; pos < ulefty + boxht -1; pos++)
       {
	gotoxy(uleftx, pos);			cprintf("%c", VLEN);
	gotoxy(uleftx + boxw-1, pos);           cprintf("%c", VLEN);
      }

   // get into the window
   window(uleftx, ulefty, uleftx + boxw-1, ulefty + boxht-1);

   gettextinfo(&t_info);
   gotoxy((t_info.winright-t_info.winleft)/2-strlen(title)/2,1);
   cputs(title);

   // resize window inside border, turn scroll on, and exit.
   window(uleftx+1,ulefty+1,uleftx+boxw-2,  ulefty+boxht-2);

   _wscroll=ON;   return OK;
  }

void Box::deactivate()
{
 window(1,1,80,25);
}

void Box::activate()
	 {
	  window(uleftx+1,ulefty+1,uleftx+boxw-2, ulefty+boxht-2);
	  textbackground(bgcolor); textcolor(fgcolor);
	  _wscroll=OFF;
	 }

void Box::setitem(char *s)
       {
	textcolor(fgcolor);
	textbackground(bgcolor);
	gotoxy(1,boxpos);
	clreol();
	cputs(s);
       }

void Box::undraw()
{
  int temp=fgcolor;
  fgcolor=bgcolor;
  settitle("");
  draw();
  textcolor(fgcolor);
  bgcolor=temp;
}
