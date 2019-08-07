OPEN "dict.txt" FOR INPUT AS #1
OPEN "palins.txt" FOR OUTPUT AS #2

CLS
DO UNTIL EOF(1) OR UCASE$(INKEY$) = "Q"
 total = total + 1
 LOCATE 2, 1: PRINT "Out of "; total; "words"
 LINE INPUT #1, word$
 FOR I = LEN(word$) TO 1 STEP -1
  char$ = MID$(word$, I, 1)
  reverse$ = reverse$ + char$
 NEXT I
 IF reverse$ = word$ THEN
  LOCATE 1, 1: PRINT "Palindromes: "; count
  BEEP: WRITE #2, word$
  count = count + 1: PRINT : PRINT word$; SPACE$(80 - LEN(word$))
 END IF
 PRINT : reverse$ = ""
LOOP
CLOSE

