#include<iostream.h>
#include<strng.h>
#include<fstream.h>
#include<conio.h>


char ** t;

void main()
{
 ifstream resfile;
 t=new char*[5];

  resfile.open("5.wrd",ios::in);
  if(resfile)
   {
    for(int i=0;i<5 && !resfile.eof();i++)
     {
      resfile.getline(t[i],70);
      strupr(t[i]);
      if(resfile.eof()) break;
     }
    resfile.close();
   }

 for(int i=0;i<5;i++)
  cout<<t[i]<<strlen(t[i]);
}
