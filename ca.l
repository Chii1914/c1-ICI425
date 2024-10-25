%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "ca.tab.h"
%}

%%
create     { return CREATE; }
grid       { return GRID; }
subgrid    { return SUBGRID; }
rows       { return ROWS; }
columns    { return COLUMNS; }
irow       { return IROW; }
icolumn    { return ICOLUMN; }
print      { return PRINT; }
make       { return MAKE; }
simulation { return SIMULATION; }
step       { return STEP; }
exposition { return EXPOSITION; }
infect     { return INFECT; }
recover    { return RECOVER; }
mortality  { return MORTALITY; }
immunity   { return IMMUNITY; }

[0-9]+           { yylval.ival = atoi(yytext); return NUMBER; } 
[0-9]+\.[0-9]+   { yylval.fval = atof(yytext); return NUMBERF; }  /* Para flotantes */
[SIR]            { yylval.str = strdup(yytext); return STATE; }

\n            { return ENDLINE; }
[ \t]+        { /* Ignore whitespace */ }
.             { printf("Unexpected character: %s\n", yytext); return 0; }

%%
