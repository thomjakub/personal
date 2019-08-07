#include "cwa.h"

char LASTFILE[30]="NULL";
int NUMRESLIST=0;
int RESNUM=0;

//SEARCH CLASS
#define FILTER 0
#define NEW 1

#define FINDWORD 0
#define ANAGRAM 1
#define LETSET 2
#define MATCHSTR 3
#define ANYSET 4

#include<stdio.h>

searchclass::searchclass()
{
 iteration=0;
 invflag=0;
 opcode=ANAGRAM;
 wlen=0;
 numfound=0;
}

searchclass::~searchclass()
{
}

long searchclass::checksum(char *s)
{
 long temp=0,i=0;
 while(s[i])
  {
   temp+=toascii(s[i]);
   i++;
  }
 return(temp);
}

int searchclass::openfiles()
{
 ifile=fopen(ifname,"r");
 if(!ifile) return(NULL);
 ofile=fopen(ofname,"w");
 if(!ofile) return(NULL);
 return(1);
}

int searchclass::wsearch(char *rawstr,int invert=0)
{
 char tempstr[30]; //Temporary strings

 if(!strlen(rawstr)) return(NULL);

 workstr=new char[strlen(rawstr)];
 strcpy(workstr,condition(rawstr));

//Set class properties
 numfound=0;
 wlen=strlen(workstr);
 invflag=invert; if(strchr(rawstr,'!')) invflag=1;

 if(strchr(rawstr,'|')) iteration++; else iteration=0;
 if(iteration==0)
   {
    itoa(wlen,ifname,10);
    strcat(ifname,".wrd");
    strcpy(ofname,"wftempcw.0");
   }
  else   //For filter mode
   {
    if(iteration%2 ==1)
     { strcpy(ifname, "wftempcw.0"); strcpy(ofname,"wftempcw.1");}
    else
     { strcpy(ifname, "wftempcw.1"); strcpy(ofname,"wftempcw.0");}
   }

 if(strchr(workstr,'?')) opcode=FINDWORD;
 else if(strchr(rawstr,'%')) opcode=LETSET;
 else if(strchr(rawstr,'#')) opcode=MATCHSTR;
 else if(strchr(rawstr,'=')) opcode=ANAGRAM;
 else if(strchr(rawstr,'*')) opcode=ANYSET;
 else opcode=FINDWORD;

 RESNUM=search(opcode);
 if(RESNUM) strcpy(LASTFILE,ofname);

 return(RESNUM);
}

int searchclass::search(int mode)
{
 char temp[30],ch;
 int flag,i;
 long chksum;

 if(mode==LETSET || mode==MATCHSTR ||mode==ANYSET)
		if(iteration==0) strcpy(ifname,"dict.txt");
 if(mode==ANAGRAM) chksum=checksum(workstr);

 status=openfiles();
 if(!status) return(NULL);

 while(!feof(ifile))
  {
   fgets(temp, 30,ifile);
   strupr(temp); temp[strlen(temp)-1]='\0';
   if(feof(ifile)) break;

   switch(mode)
   {
    case FINDWORD:
	flag=1;
	for(int i=0;i<wlen;i++)
	if(workstr[i] !='?')
	 if(workstr[i]!=temp[i])
	  flag = 0;
	break;

    case ANAGRAM:
	flag=1;
	if(chksum!=checksum(temp)) flag=0;
	if(flag)
	 for(i=0;i<wlen && temp[i];i++)
	  if(!strchr(temp,workstr[i])) flag=0;
	break;

    case LETSET:
	flag=1;
	for(i=0;i<wlen && flag;i++)
	 if(!strchr(temp,workstr[i]))
	  flag=0;
	break;

    case MATCHSTR:
	flag=1;
	if(!strstr(temp,workstr))
	 flag=0;
	break;

    case ANYSET:
	flag=0;
	for(i=0;i<wlen && !flag; i++)
	 if(strchr(temp,workstr[i])) flag=1;
	break;
   }

   if(invflag) flag=!flag;  //Invert the result status
   if(flag)
    { fputs(temp,ofile); fprintf(ofile,"\n"); numfound++;}
  }
 fclose(ifile); fclose(ofile);

 return(numfound);
}

char* searchclass::condition(char* rawstr)
{
 int i=0,j=0;
 char *temp;

 strtrim(rawstr); strupr(rawstr);
 temp=new char[strlen(rawstr)+1];

 //Extract only alphabets from the raw string
 do
 {
  if(isalpha(rawstr[i]) || rawstr[i]=='\0' || rawstr[i]=='?')
		temp[j++]=rawstr[i];
  if(rawstr[i]==' ') temp[j++]='?';

 }while(rawstr[i++]);

 return(temp);
}

