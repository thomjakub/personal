#include "cwa.h"

ResList::ResList()
{
 start=0;
 settitle("Results");
 hkeys=0; //Disable menu hotkeys
 menurow=1;
 maxitemlen=8;
 itemtext=new char*[MAXITEMS];
}

void ResList::getitems(int nm, char *filename) //Items taken from file
 {
  //For use with CWA
  char *temp;
  start=0;
  settitle("Results");
  hkeys=0; //Disable menu hotkeys
  menurow=1;
  maxitemlen=8;

  n=abs(nm);        //Store actual number of items in object
  if(n+1>MAXITEMS) n=MAXITEMS;

  listsize=15;
  if(listsize>n) listsize=n;

  resfile=fopen(filename,"r");
  if(resfile)
   {
    for(int i=0;i<n && !feof(resfile);i++)
     {
      temp=new char[30];
      fgets(temp,30,resfile);
      strupr(temp);
      if(strlen(temp)>maxitemlen)
       maxitemlen=strlen(temp);
      itemtext[i]=temp;
      itemtext[i][strlen(temp)-1]= '\0';
      if(feof(resfile)) break;
     }
    fclose(resfile);
   }
   boxw=maxitemlen+5;
   boxht=listsize+2;
 }


ResList::~ResList()
 {  delete itemtext; }

void ResList::freemem()
{
 delete itemtext;
}

void ResList::movebar(int mode)
 {
  switch(mode)
   {case MUP: 	menurow=(menurow-1)%(listsize+1);
		if(menurow==0)
		 {
		  if(start-1>0) start--;
		  else start=0;
		  menurow=1;
		 }
		break;
    case MDOWN: menurow=(menurow+1)%(listsize+1);
		if(menurow==0)
		 {
		  if(start+listsize<n) start++;
		  menurow=listsize;
		 }
   }
  writeitemlist();
  highlight();
 }

