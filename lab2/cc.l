%option noyywrap nodefault yylineno
%{
#include "cc.h"
#include "cc.tab.h"

int yycolumn = 1;
#define YY_USER_ACTION \
  yylloc.first_line = yylloc.last_line = yylineno; \
  yylloc.first_column = yycolumn; \
  yylloc.last_column = yycolumn + yyleng - 1; \
  yycolumn += yyleng;
%}
/* basic symbols */
wspace    [ \t]
letter   [_A-Za-z]
digit    [0-9]
hexdigit [0-9a-fA-F]

/* combination of basic symbols */
ws       {wspace}+
id       {letter}({letter}|{digit})*
wid      {digit}+{letter}({digit}|{letter})*
float    [+-]?{digit}+\.{digit}+
nfloat   [+-]?(({digit}+\.{digit}+)|(\.{digit}+)|({digit}+\.))
wfloat   {float}[eE]{float}
efloat   ({nfloat}|{int})[eE][+-]?{int}
int      (({digit}+)|(0[xX]{hexdigit}+))
op       [+-/*]
semi     ;
comma    [,]
assign   =
relop    >|<|(>=)|(<=)|(==)|(!=)
and      &&
or       \|\|
dot      \.
not      !
type     (int)|(float)
lp       \(
rp       \)
lb       \[
rb       \]
lc       \{
rc       \}
struct   struct
return   return
if       if
else     else
while    while
%%
\n       { yycolumn = 1; }
"//".*   { }
{ws}     { } /* WHITE SPACE */
{if}     { return IF; } /* IF */
{else}   { return ELSE; } /* ELSE */
{while}  { return WHILE; } /* WHILE */
{struct} { return STRUCT; } /* STRUCT */
{return} { return RETURN; } /* RETURN */
{not}    { return NOT; } /* NOT */
{type}   { yylval.id = malloc(strlen(yytext)); strcpy(yylval.id, yytext); return TYPE; } /* TYPE */
{lp}     { return LP; } /* LP */
{rp}     { return RP; } /* RP */
{lb}     { return LB; } /* LB */
{rb}     { return RB; } /* RB */
{lc}     { return LC; } /* LC */
{rc}     { return RC; } /* RC */
{dot}    { return DOT; } /* DOT */
{comma}  { return COMMA; } /* COMMA */
{int}    { yylval.i = atoi(yytext); return INT; } /* INT */
{float}  { yylval.d = atof(yytext); return FLOAT; } /* FLOAT1 */
{efloat} { yylval.d = atof(yytext); return FLOAT; } /* FLOAT2 */
{nfloat} { f2p = 1; printf("Error type A at Line %d: wrong float \"%s\".\n", yylineno, yytext); return FLOAT; }
"+"      { return PLUS; } /* PLUS */
"-"      { return MINUS; } /* MINUS */
"*"      { return STAR; } /* STAR */
"/"      { return DIV; } /* DIV */
{and}    { return AND; } /* AND */
{or}     { return OR; } /* OR */
{semi}   { return SEMI; } /* SEMI */
{assign} { return ASSIGNOP; } /* ASSIGNOP */
{relop}  { return RELOP; } /* RELOP */
{id}     { yylval.id = malloc(strlen(yytext)); strcpy(yylval.id, yytext); return ID; } /* ID */
{wid}    { printf("Error type A at Line %d: wrong id \"%s\".\n", yylineno, yytext); f2p = 1; return ID;}
.        { printf("Error type A at Line %d: unknown character \"%s\".\n", yylineno, yytext); f2p = 1; }
%%
/*
int main(int argc, char **argv) {
    FILE *f = fopen("a.in", "r");
    yyrestart(f);
    yylex();
}*/
