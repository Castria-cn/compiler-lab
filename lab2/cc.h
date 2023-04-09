#include <stdio.h>
int f2p;
extern int yylineno;

void report_error(char *s, int lineno, char *type, ...);
// void report_error(char *s, int lineno, char *type);

void yyerror(char *s, ...);

void yyrestart(FILE *f);

int yylex_destroy(void);

int yylex();
