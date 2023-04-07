%{
#include <stdio.h>
#include <stdlib.h>
#include "cc.h"
%}
/*
several kinds of terminal symbol:
1. int
2. float
3. id
else the symbol is non-terminal, represented as AST
*/
%union {
    struct ast *a;
    int i;
    float d;
    char *id;
    char *type;
}

%token <i> INT
%token EOL
%token <d> FLOAT
%token <id> ID
%token <type> TYPE
%token SEMI COMMA ASSIGNOP RELOP PLUS MINUS STAR DIV AND OR DOT NOT LP RP LB RB LC RC STRUCT RETURN IF ELSE WHILE

%left AND OR
%left RELOP
%left PLUS MINUS
%left STAR DIV
%right NOT UMINUS

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%type <a> Program ExtDefList ExtDef ExtDecList Specifier StructSpecifier OptTag Tag VarDec FunDec VarList ParamDec CompSt StmtList Stmt DefList Def DecList Dec Exp Args
%%
Program: ExtDefList {
    root = make_ast("Program", make_list(1, $1));
};

ExtDefList: {$$ = make_ast("ExtDefList", new_list()); }
| ExtDef ExtDefList {
    $$ = make_ast("ExtDefList", make_list(2, $1, $2));
};

ExtDef: Specifier ExtDecList SEMI {
    $$ = make_ast("ExtDef", make_list(3, $1, $2, make_terminal("SEMI", @3.first_line)));
}
| Specifier SEMI { $$ = make_ast("ExtDef", make_list(2, $1, make_terminal("SEMI", @2.first_line))); }
| Specifier FunDec CompSt { $$ = make_ast("ExtDef", make_list(3, $1, $2, $3)); }
| Specifier error SEMI { report_error("ExtDef error; Sync with SEMI", @3.first_line); }
| Specifier error { report_error("ExtDef error; Missing ';'?", @2.first_line); };

ExtDecList: VarDec { $$ = make_ast("ExtDecList", make_list(1, $1)); }
| VarDec COMMA ExtDecList { $$ = make_ast("ExtDecList", make_list(3, $1, make_terminal("COMMA", @2.first_line), $3)); };

Specifier: TYPE { $$ = make_ast("Specifier", make_list(1, make_type($1, @1.first_line))); }
| StructSpecifier { $$ = make_ast("Specifier", make_list(1, $1)); };

StructSpecifier: STRUCT OptTag LC DefList RC { $$ = make_ast("StructSpecifier", make_list(5, make_terminal("STRUCT", @1.first_line), $2, make_terminal("LC", @3.first_line), $4, make_terminal("RC", @5.first_line))); }
| STRUCT Tag { $$ = make_ast("StructSpecifier", make_list(2, make_terminal("STRUCT", @1.first_line), $2)); };

OptTag: { $$ = make_ast("OptTag", new_list()); }
| ID { $$ = make_ast("OptTag", make_list(1, make_id($1, @1.first_line))); };

Tag: ID { $$ = make_ast("Tag", make_list(1, make_id($1, @1.first_line))); };

VarDec: ID { $$ = make_ast("VarDec", make_list(1, make_id($1, @1.first_line))); }
| VarDec LB INT RB { $$ = make_ast("VarDec", make_list(4, $1, make_terminal("LB", @2.first_line), make_int($3, @3.first_line), make_terminal("RB", @4.first_line))); }
| error RB { report_error("VarDec error; Sync with RB", @2.first_line); };

FunDec: ID LP VarList RP { $$ = make_ast("FunDec", make_list(4, make_id($1, @1.first_line), make_terminal("LP", @2.first_line), $3, make_terminal("RP", @4.first_line))); }
| ID LP RP { $$ = make_ast("FunDec", make_list(3, make_id($1, @1.first_line), make_terminal("LP", @2.first_line), make_terminal("RP", @3.first_line))); }
| error RP { report_error("FunDec error; Sync with RP", @2.first_line); };

VarList: ParamDec COMMA VarList { $$ = make_ast("VarList", make_list(3, $1, make_terminal("COMMA", @2.first_line), $3)); }
| ParamDec error VarList { report_error("VarList error; Sync with VarList", @1.first_line); }
| ParamDec { $$ = make_ast("VarList", make_list(1, $1)); };

ParamDec: Specifier VarDec { $$ = make_ast("ParamDec", make_list(2, $1, $2)); };

CompSt: LC DefList StmtList RC { $$ = make_ast("CompSt", make_list(4, make_terminal("LC", @1.first_line), $2, $3, make_terminal("RC", @4.first_line))); }
| error RC { report_error("CompSt error; Sync with RC", @2.first_line); };

StmtList: { $$ = make_ast("StmtList", new_list()); }
| Stmt StmtList { $$ = make_ast("StmtList", make_list(2, $1, $2)); };

Stmt: Exp SEMI { $$ = make_ast("Stmt", make_list(2, $1, make_terminal("SEMI", @2.first_line))); }
| CompSt { $$ = make_ast("Stmt", make_list(1, $1)); }
| RETURN Exp SEMI { $$ = make_ast("Stmt", make_list(3, make_terminal("RETURN", @1.first_line), $2, make_terminal("SEMI", @3.first_line)));}
| IF LP Exp RP Stmt %prec LOWER_THAN_ELSE { $$ = make_ast("Stmt", make_list(5, make_terminal("IF", @1.first_line), make_terminal("LP", @2.first_line), $3, make_terminal("RP", @4.first_line), $5)); }
| IF LP Exp RP Stmt ELSE Stmt { $$ = make_ast("Stmt", make_list(7, make_terminal("IF", @1.first_line), make_terminal("LP", @2.first_line), $3, make_terminal("RP", @4.first_line), $5, make_terminal("ELSE", @6.first_line), $7)); }
| WHILE LP Exp RP Stmt { $$ = make_ast("Stmt", make_list(5, make_terminal("WHILE", @1.first_line), make_terminal("LP", @2.first_line), $3, make_terminal("RP", @4.first_line), $5)); } 
| error SEMI { report_error("Stmt error; Sync with SEMI", @2.first_line); }
| error ELSE { report_error("Stmt error; Sync with ELSE", @1.first_line); }
| WHILE LP error RP Stmt { report_error("Stmt error; Wrong while exp", @2.first_line);}
| IF LP error RP Stmt { report_error("Stmt error; Wrong if exp", @2.first_line); };

DefList: { $$ = make_ast("StmtList", new_list()); }
| Def DefList { $$ = make_ast("DefList", make_list(2, $1, $2)); };

Def: Specifier DecList SEMI { $$ = make_ast("Def", make_list(3, $1, $2, make_terminal("SEMI", @3.first_line))); }
| Specifier DecList error { report_error("Def error", @2.first_line); }
| Specifier error SEMI { report_error("Def error; DecList error", @3.first_line); };

DecList: Dec { $$ = make_ast("DecList", make_list(1, $1)); }
| Dec COMMA DecList { $$ = make_ast("DecList", make_list(3, $1, make_terminal("COMMA", @2.first_line), $3)); };
Dec: VarDec { $$ = make_ast("Dec", make_list(1, $1)); }
| VarDec ASSIGNOP Exp { $$ = make_ast("Dec", make_list(3, $1, make_terminal("ASSIGNOP", @2.first_line), $3)); };

Exp: Exp ASSIGNOP Exp { $$ = make_ast("Exp", make_list(3, $1, make_terminal("ASSIGNOP", @2.first_line), $3)); }
| Exp AND Exp { $$ = make_ast("Exp", make_list(3, $1, make_terminal("AND", @2.first_line), $3)); }
| Exp OR Exp { $$ = make_ast("Exp", make_list(3, $1, make_terminal("OR", @2.first_line), $3)); }
| Exp RELOP Exp { $$ = make_ast("Exp", make_list(3, $1, make_terminal("RELOP", @2.first_line), $3)); }
| Exp PLUS Exp { $$ = make_ast("Exp", make_list(3, $1, make_terminal("PLUS", @2.first_line), $3)); }
| Exp MINUS Exp { $$ = make_ast("Exp", make_list(3, $1, make_terminal("MINUS", @2.first_line), $3)); }
| Exp STAR Exp { $$ = make_ast("Exp", make_list(3, $1, make_terminal("STAR", @2.first_line), $3)); }
| Exp DIV Exp { $$ = make_ast("Exp", make_list(3, $1, make_terminal("DIV", @2.first_line), $3)); }
| LP Exp RP { $$ = make_ast("Exp", make_list(3, make_terminal("LP", @1.first_line), $2, make_terminal("RP", @3.first_line))); }
| MINUS Exp %prec UMINUS { $$ = make_ast("Exp", make_list(2, make_terminal("MINUS", @1.first_line), $2)); }
| NOT Exp { $$ = make_ast("Exp", make_list(2, make_terminal("NOT", @1.first_line), $2)); }
| ID LP Args RP { $$ = make_ast("Exp", make_list(4, make_id($1, @1.first_line), make_terminal("LP", @2.first_line), $3, make_terminal("RP", @4.first_line))); }
| ID LP RP { $$ = make_ast("Exp", make_list(3, make_id($1, @1.first_line), make_terminal("LP", @2.first_line), make_terminal("RP", @3.first_line))); }
| Exp LB Exp RB { $$ = make_ast("Exp", make_list(4, $1, make_terminal("LB", @2.first_line), $3, make_terminal("RB", @4.first_line))); }
| Exp DOT ID { $$ = make_ast("Exp", make_list(3, $1, make_terminal("DOT", @2.first_line), make_id($3, @3.first_line))); }
| ID { $$ = make_ast("Exp", make_list(1, make_id($1, @1.first_line))); }
| INT { $$ = make_ast("Exp", make_list(1, make_int($1, @1.first_line))); }
| FLOAT { $$ = make_ast("Exp", make_list(1, make_float($1, @1.first_line))); };

Args: Exp COMMA Args { $$ = make_ast("Args", make_list(3, $1, make_terminal("COMMA", @2.first_line), $3)); }
| Exp { $$ = make_ast("Exp", make_list(1, $1));};

%%
