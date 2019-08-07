#include<stdio.h>
#include<conio.h>
#include<iostream.h>
#include<fstream.h>

void main()
{
 char s[30];
 FILE *f;

 f=fopen("3.wrd","r");
 while(!feof(f))
  {
   fgets(s,4,f);
   cout<<s;
  }
 fclose(f);
}



