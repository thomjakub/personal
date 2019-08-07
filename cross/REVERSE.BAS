OPEN "dict.txt" FOR INPUT AS #1

DO UNTIL EOF(1) OR UCASE$(INKEY$) = "Q"


 LINE INPUT #1, word$
 FOR I = LEN(word$) TO 1 STEP -1
  char$ = MID$(word$, I, 1)
  reverse$ = reverse$ + char$
 NEXT I




 PRINT : reverse$ = ""
LOOP
CLOSE

