struct ast {
    int lnum;
    char *type;
    void *value;
    struct listnode *children;
};

int f2p;
extern int yylineno;

#include <stdio.h>

enum non_terminal {
    Program, ExtDefList, ExtDef, ExtDecList, Specifier, StructSpecifier, OptTag, Tag, VarDec, FunDec, VarList, ParamDec, CompSt, StmtList, Stmt, DefList, Def, DecList, Dec, Exp, Args
};

struct ast *root;

typedef struct ast* data;

struct listnode {
    data value;
    struct listnode *next;
};

/**
 * Returns a new linked list.
 */
struct listnode *new_list();

/**
 * Add a node given a linked list's head.
 */
void add_node(struct listnode *head, data value);

struct listnode* make_list(int num, ...);

int get_length(struct listnode *head);

struct ast *make_ast(char *type, struct listnode *children);

struct ast *make_int(int i, int lnum);

struct ast *make_float(float f, int lnum);

struct ast *make_id(char *s, int lnum);

struct ast *make_type(char *s, int lnum);

struct ast *make_terminal(char *type, int lnum);

void report_error(char *s, int lineno);

void yyerror(char *s, ...);

void yyrestart(FILE *f);

int yylex_destroy(void);

int yylex();
