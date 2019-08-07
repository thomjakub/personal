#include "cwa.h"
#include<fstream.h>

extern char LASTFILE[30];
extern int NUMRESLIST;
extern int RESNUM;

char LASTRESULT[30];

ResList reslist;
searchclass Search;

int symmetry=NONE;
int movedir=RIGHT;

void gridclass::init()
{
 clrscr();
 drawgrid();
 fillgrid();
 helpscrn();
}

void gridclass::newgrid()
{
 size=atoi(strprompt("Size: "));
 if(size==15) size=15; else size=10;
 for(int i=1;i<=size;i++)
  for(int j=1;j<=size;j++)
    cell[i][j].value=' ';
 init();
}

char gridclass::nextcell(int i=1)
{
 if(movedir==RIGHT) return(cell[crow][ccol+i].value);
 else return(cell[crow+i][ccol].value);
}

int gridclass::nextcurpos(int i=1)
{
 if(movedir==RIGHT) return(ccol+i);
 else return(crow+i);
}

void gridclass::reset()
{
 for(int i=1;i<=size;i++)
  for(int j=1;j<=size;j++)
   if(cell[i][j].value!=char(BLOCK))
    {
     cell[i][j].value=' ';
     fillcell(i,j);
    }

}
void gridclass::intellimove()
{
 int flag=0;
 //Analyse position
   if( nextcell()==char(BLOCK) && nextcell(-1)==char(BLOCK)) flag=1;
   if( nextcell()==char(BLOCK) && nextcurpos(-1) < 1) flag=1;
   if( nextcell(-1)==char(BLOCK) && nextcurpos() >size) flag=1;

 if(flag) movedir=!movedir;
}

int gridclass::iscluestart(int m=movedir)
{
 if(cell[crow][ccol].value==char(BLOCK)) return(0);//if block not a clue

 if(m!=movedir) movedir=m;
 if(nextcell()==char(BLOCK)) return(0);
 if(nextcell(-1)== char(BLOCK) ) return(1);
 if(nextcurpos(-1)< 1) return(1);

 return(0);
}

void gridclass::solvecur()
{
 int status;
 status=Search.wsearch(clue,0);
 if(status)
  {
   reslist.getitems(status, LASTFILE);
   strcpy(clue,reslist.operate());
   strcpy(LASTRESULT,clue);
   insert(clue);
  }
}

int gridclass::insert(char *s)
{
 int l=strlen(s);

 intellimove();
 if(nextcurpos(l-1)>size) return(0);
 if(streql(s," ")) return(0);

 for(int i=0;i<l;i++)
  {
   if(movedir==RIGHT)
    { cell[crow][ccol+i].value=s[i];  fillcell(crow,ccol+i); }
   else
    { cell[crow+i][ccol].value=s[i];  fillcell(crow+i,ccol); }
  }
 return(1);
}

char* gridclass::getclue()
{
 int breakout=0;
 char *temp=new char[16];

 while(!iscluestart()) //Go backwards till start of clue if not a clue
  {
     if(nextcurpos(-1)>0)
     if(nextcell(-1)!=char(BLOCK))
      {
       if(movedir==RIGHT) ccol--;
       else crow--;
      }
  }
 cluebegrow=crow; cluebegcol=ccol; //Store position of clue

 //At start now, retrieve the clue
 int i=0;
 while(1)
  {
   if(nextcell(0)==' ') temp[i]='?'; else temp[i]=nextcell(0);
   i++;
   if(nextcurpos()>size) breakout=1;
   if(nextcell() == char(BLOCK)) breakout=1;

   if(!breakout)
    { if(movedir==RIGHT) ccol++;  else crow++; }
   else break;
  }

  //Out of loop, store valid data
  cluelen=i; temp[i]='\0';
  crow=cluebegrow; ccol=cluebegcol;
  return(temp);
}

int gridclass::save()
{
 char *fname=new char[40];

 fname=strprompt("File to save to: ");
 if(!strstr(fname,".")) strcat(fname,".grd");

 ofstream ofile(fname,ios::out|ios::binary);
 if(!ofile) {pause("Error saving to file."); return(0);}
 ofile.write((char*)this,sizeof(gridclass));

 ofile.close(); delete fname;
 return(1);
}

int gridclass::load()
{
 char *fname=new char[80];
 fname=strprompt("File to load: ");

 if(!strstr(fname,".")) strcat(fname,".grd");
 ifstream ifile(fname,ios::in|ios::binary);
 if(!ifile) {pause("Error loading file.");return(0);}

 ifile.read((char*)this,sizeof(gridclass));
 init();
 return(1);
}

void gridclass::fillgrid()
{
 for(int i=1;i<=size;i++)
  for(int j=1;j<=size;j++)
   fillcell(i,j);
}

gridclass::gridclass(int s)
{
 //Assign size of grid
 if(s==15) size=s;  else size=10;

 //Initialize values in cells
 for(int i=1;i<=15;i++)
  for(int j=1;j<=15;j++)
   cell[i][j].value= ' ';

  crow=1; ccol=1; //Active cell
}

void gridclass::movecursor(int mode)
{
 switch(mode)
  {
   case UP:    	   if(crow>1) crow--; break;
   case DOWN:	   if(crow<size) crow++; break;
   case RIGHT:     if(ccol<size) ccol++; break;
   case LEFT:	   if(ccol>1) ccol--; break;
  }
}

void gridclass::setvalue(char c)
{
 if(c!=char(BLOCK))
  cell[crow][ccol].value=c;
 else
  if(cell[crow][ccol].value==char(BLOCK)) //toggle shaded/not shaded
   cell[crow][ccol].value=' ';  //Symmetry not considered for unblocking
  else
   {
    cell[crow][ccol].value=char(BLOCK);
    switch(symmetry)
     {
      case FOURWAY:
			if(cell[crow][size-ccol+1].value==' ')
			    cell[crow][size-ccol+1].value=char(BLOCK);
			fillcell(crow,size-ccol+1);
			if(cell[size-crow+1][ccol].value==' ')
			    cell[size-crow+1][ccol].value=char(BLOCK);
			fillcell(size-crow+1,ccol);

      case TWOWAY:
		    if(cell[size-crow+1][size-ccol+1].value==' ')
		     cell[size-crow+1][size-ccol+1].value=char(BLOCK);
		    fillcell(size-crow+1,size-ccol+1);

     }
   }
}

void gridclass::fillcell()
{
 gotoxy(convcol(ccol),convrow(crow));

 if(cell[crow][ccol].value==char(BLOCK))
  cout<<char(BLOCK)<<char(BLOCK)<<"\b\b";
 else  cout<<cell[crow][ccol].value<<" \b\b";
}

void gridclass::fillcell(int row,int col)
{
 int savr=crow,savc=ccol;
 crow=row; ccol=col;
 fillcell();
 crow=savr; ccol=savc;
}

int gridclass::convrow(int row)
 {
  if(size==10) return(2*row);
  else return(row+1);
 }

int gridclass::convcol(int col)
 {
  if(size==10) return((col-1)*5 + 3);
  else return(1+ col*2);
 }

void gridclass::operate()
{
 int c,status;

 _setcursortype(_SOLIDCURSOR);
 helpscrn();
 do
  {
   fillcell();
   statusline();
   c=scan();
   switch(c)
   {
    case UPKEY: 	movecursor(UP); break;
    case DOWNKEY:	movecursor(DOWN); break;
    case RIGHTKEY:	movecursor(RIGHT); break;
    case LEFTKEY: 	movecursor(LEFT); break;

    case HOMEKEY:       ccol=1;break;
    case ENDKEY:        ccol=size;break;
    case PGUPKEY:       crow=1;break;
    case PGDNKEY:       crow=size;break;

    case BKSPKEY:	if(movedir==DOWN) movecursor(UP);
			else movecursor(LEFT);
    case DELKEY:        setvalue(' '); fillcell(); break;

    case ENTERKEY:
			if(cell[crow][ccol].value==char(BLOCK)) break;
			intellimove();
			strcpy(clue,getclue());
			solvecur();
			break;


    case TABKEY:   movedir=!movedir; break;
    case INSKEY:   if(streql(LASTRESULT," "))
			pause("No result to insert.");
		   else if(!insert(LASTRESULT))
			pause("Could not insert result.");
    		   break;

    case CTRLS:    symmetry=(symmetry+1)%3; break;
    case CTRLN:    newgrid();
		   break;

    case ESCKEY:   break;

    case CTRLK:
    case F2KEY:    save();
		   break;
    case CTRLL:
    case F3KEY:    load();
		   init();
		   break;

    case F5KEY:    if(iscluestart()) pause("Is a clue."); break;

    case CTRLA:    reset();
		   break;

    case CTRLF:    symmetry=NONE;
		   intellimove();
		   movedir=RIGHT;
		   break;

    case CTRLC:    symmetry=FOURWAY;
		   intellimove();
		   movedir=RIGHT;
		   reset();
		   break;

    case SPCKEY:   c=BLOCK;
    default:
		   if(!isalpha(c) && c!=BLOCK) break;
    		   c=toupper(c);
		   setvalue(c);
		   fillcell();
		   intellimove();
		   if(nextcell()!=char(BLOCK))
		    movecursor(movedir); //automove
		   break;
   }
  }while(c!=ESCKEY);
  Box HelpBox;  HelpBox.setsize(MENUPOSX,1,25,20); HelpBox.undraw();
  _setcursortype(_NORMALCURSOR);

}

void gridclass::drawgrid()
{
 int i,j;

 if(size==10)
  {
   for(j=1;j<=22;j+=2)                 //draw main box (horizontal)
   for(i=1;i<52;i++)
    { gotoxy(i,j); cout<<char(HLEN);}

  for(j=1;j<=55;j+=5)                 //draw main box (vertical)
   for(i=2;i<=20;i++)
    { gotoxy(j,i); cout<<char(VLEN); }

  gotoxy(1,1);cout<<char(TLFTCNR);    //fixes corners
  gotoxy(51,1);cout<<char(TRGTCNR);
  gotoxy(1,21);cout<<char(BLFTCNR);
  gotoxy(51,21);cout<<char(BRGTCNR);

  for(i=6;i<=50;i+=5)                 // completes lines
   { gotoxy(i,1); cout<<char(TCTR); gotoxy(i,21);cout<<char(BCTR);  }

  for(i=3;i<=20;i+=2)                 // completes lines
   { gotoxy(1,i);cout<<char(LCTR); gotoxy(51,i);cout<<char(RCTR); }

  for(i=6;i<=50;i+=5)                 // completes lines
   for(j=3;j<20;j+=2)  { gotoxy(i,j);cout<<char(CTR); }
  }

 else 		//15x15 grid
  {
    Box GBord;
    GBord.setsize(1,1,34,17);
    GBord.draw();
    GBord.deactivate();
  }
}

void gridclass::helpscrn()
{
 Box HelpBox;
 HelpBox.setsize(MENUPOSX,1,25,20);
 HelpBox.draw();
 HelpBox.setitem("-Commands-           "); HelpBox.boxpos++;
 HelpBox.setitem("CTRL N    -New grid  "); HelpBox.boxpos++;
 HelpBox.setitem("CTRL A    -Reset grid"); HelpBox.boxpos++;
 HelpBox.setitem("CTRL K,F2 -Save grid "); HelpBox.boxpos++;
 HelpBox.setitem("CTRL L,F3 -Load grid "); HelpBox.boxpos++;
 HelpBox.setitem("CTRL S    -Symmetry  "); HelpBox.boxpos++;
 HelpBox.setitem("                     "); HelpBox.boxpos++;
 HelpBox.setitem("-Key Controls-       "); HelpBox.boxpos++;
 HelpBox.setitem("SPACE- Block/Unblock "); HelpBox.boxpos++;
 HelpBox.setitem("TAB  - Change dir    "); HelpBox.boxpos++;
 HelpBox.setitem("ENTER- Solve clue!   "); HelpBox.boxpos++;
 HelpBox.setitem("INS  - Insert result "); HelpBox.boxpos++;
 HelpBox.setitem("DEL  - Clear cell    "); HelpBox.boxpos++;
 HelpBox.setitem("HOME - Start of row"); HelpBox.boxpos++;
 HelpBox.setitem("END  - End of row  "); HelpBox.boxpos++;
 HelpBox.setitem("PAGEUP - Start of col"); HelpBox.boxpos++;
 HelpBox.setitem("PAGEDN - End of col "); HelpBox.boxpos++;


 HelpBox.deactivate();
 statusline();
}

void gridclass::statusline()
{
 int tempx=wherex(); int tempy=wherey();
 gotoxy(1,22);
 printf(" CELL( %2d, %2d) ", crow,ccol);
 cout<<"<SYMMETRY: ";
 switch(symmetry)
  {
   case 0     :	        cout<<"  NONE  >"; break;
   case TWOWAY: 	cout<<"TWO-WAY >"; break;
   case FOURWAY: 	cout<<"FOUR-WAY>"; break;
  }
  cout <<" <MOVE: ";
  switch(movedir)
  {
   case RIGHT:		cout<<"ACROSS>";break;
   case DOWN :          cout<<" DOWN >";break;
  }
  cout<<"     ";
 gotoxy(tempx,tempy);
}

void gridclass::print()
{
 int k;
 FILE *t;

//For printing cell depending on info
 char col[3][5]={"|   ","|   ","----",};
 char line[3][80]={"","",""};

 for(k=1;k<=size*4;k++)
  fprintf(stdprn,"_");
 fprintf(stdprn,"\n");

 for(int crow=1;crow<=size;crow++)
  {
   for(int ccol=1;ccol<=size;ccol++)
    {
     if(cell[crow][ccol].value!=char(BLOCK))
      {
       col[0][1]=' '; col[0][2]=' '; col[0][3]=' ';
       col[1][1]=' ';  col[1][2]=cell[crow][ccol].value; col[1][3]=' ';
      }
     else
      {
	col[0][1]='$'; col[0][2]='$'; col[0][3]='$';
	col[1][1]='$'; col[1][2]='$'; col[1][3]='$';
      }
     strcat(line[0],col[0]);  strcat(line[1],col[1]); strcat(line[2],col[2]);
    }
   strcat(line[0],"|"); strcat(line[1],"|");
   fprintf(stdprn,"%s\n%s\n%s\n",line[0],line[1],line[2]);
   strcpy(line[0],"");   strcpy(line[1],""); strcpy(line[2],"");
  }

 crow=1; ccol=1;
}