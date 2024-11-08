%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "ca.tab.h"
%}

%%
create     { return CREATE; }
grid       { return GRID; }
grids      { return GRIDS; }
id         { return ID; }
m          { return M; }
n          { return N; }
set        { return SET; }
area       { return AREA; }
cells      { return CELLS; }
all        { return ALL; }
rows       { return ROWS; }
columns    { return COLUMNS; }
irow       { return IROW; }
icolumn    { return ICOLUMN; }
print      { return PRINT; }
make       { return MAKE; }
simulation { return SIMULATION; }
step       { return STEP; }
release    { return RELEASE; }
memory     { return MEMORY; }

[0-9]+           { yylval.ival = atoi(yytext); return NUMBER; } 
[SEIR]            { yylval.str = strdup(yytext); return STATE; }

\n            { return ENDLINE; }
[ \t]+        { /* Ignore whitespace */ }
.             { printf("Unexpected character: %s\n", yytext); return 0; }

%%
