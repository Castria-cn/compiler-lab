%{
#include <stdio.h>
#include <stdlib.h>
#include "cc.h"
#include "symbol_table.h"

int label;
int type, fun_dec;
char *fun_name, *calling;
%}

%union {
    char *str;
    int int_value;
    float float_value;
    struct { int id, read; void *true_list, *false_list; } exp;
    struct { void *next_list; } stmt;
}

%token <int_value> INT
%token <float_value> FLOAT
%token <str> ID RELOP TYPE
%token SEMI COMMA ASSIGNOP PLUS MINUS STAR DIV AND OR DOT NOT LP RP LB RB LC RC STRUCT RETURN IF ELSE WHILE

%left AND OR
%left RELOP
%left PLUS MINUS
%left STAR DIV
%right NOT UMINUS

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%type <exp> Exp Args
%type <stmt> Stmt N CompSt StmtList
%type <int_value> M
%%
Program: ExtDefList {
};

ExtDefList: {}
| ExtDef ExtDefList {
};

ExtDef: Specifier ExtDecList SEMI {
}
| Specifier SEMI { }
| Specifier FunDec CompSt { }
| Specifier error SEMI { report_error("ExtDef error; Sync with SEMI", @3.first_line, "B"); }
| Specifier error { report_error("ExtDef error; Missing ';'?", @2.first_line, "B"); };

ExtDecList: VarDec {  }
| VarDec COMMA ExtDecList {  };

Specifier: TYPE { type = strcmp($1, "int") == 0? TYPE_INT: TYPE_FLOAT; }
| StructSpecifier { };

StructSpecifier: STRUCT OptTag LC DefList RC {

}
| STRUCT Tag {  };

OptTag: {  }
| ID {  };

Tag: ID {  };

VarDec: ID {
    if (fun_dec) {
        add_arg(table, fun_name, type, $1);
        add_var(table, $1, type);
        gen("PARAM t%d", var_id);
    }
    else add_var(table, $1, type);
}
| VarDec LB INT RB {  }
| error RB { report_error("VarDec error; Sync with RB", @2.first_line, "B"); };

FunDec: ID LP {
    fun_dec = 1;
    fun_name = malloc(strlen($1));
    strcpy(fun_name, $1);
    add_fun(table, $1, type);
    gen("FUNCTION %s :", $1);
} VarList RP { fun_dec = 0; }
| ID LP RP { gen("FUNCTION %s :", $1); add_fun(table, $1, type); }
| error RP { report_error("FunDec error; Sync with RP", @2.first_line, "B"); };

VarList: ParamDec COMMA VarList {  }
| ParamDec error VarList { report_error("VarList error; Sync with VarList", @1.first_line, "B"); }
| ParamDec {  };

ParamDec: Specifier VarDec {
};
CompSt: LC DefList StmtList RC { $$.next_list = $3.next_list; }
| error RC { report_error("CompSt error; Sync with RC", @2.first_line, "B"); };

StmtList: { $$.next_list = NULL; }
| Stmt M StmtList {
    backpatch($1.next_list, $2);
    // printf("Stmt.next_list = %x\n", $1.next_list);
    // $$.next_list = merge($1.next_list, $3.next_list);
};

Stmt: Exp SEMI { $$.next_list = NULL; }
| CompSt { $$.next_list = NULL; }
| RETURN Exp SEMI {
    gen("RETURN t%d", $2.id);
    $$.next_list = NULL;
}
| IF LP Exp RP M Stmt %prec LOWER_THAN_ELSE {
    $$.next_list = merge($3.false_list, $6.next_list);
    backpatch($3.true_list, $5);
}
| IF LP Exp RP M Stmt ELSE N M Stmt {
    $$.next_list = merge(merge($6.next_list, $10.next_list), $8.next_list);
    backpatch($3.true_list, $5);
    backpatch($3.false_list, $9);
}
| WHILE LP Exp RP Stmt {  }
| error SEMI { report_error("Stmt error; Sync with SEMI", @2.first_line, "B"); }
| error ELSE { report_error("Stmt error; Sync with ELSE", @1.first_line, "B"); }
| WHILE LP error RP Stmt { report_error("Stmt error; Wrong while exp", @2.first_line, "B");}
| IF LP error RP Stmt { report_error("Stmt error; Wrong if exp", @2.first_line, "B"); };

DefList: {  }
| Def DefList {
};

Def: Specifier DecList SEMI {
}
| Specifier DecList error { report_error("Def error", @2.first_line, "B"); }
| Specifier error SEMI { report_error("Def error; DecList error", @3.first_line, "B"); };

DecList: Dec {
}
| Dec COMMA DecList { };
Dec: VarDec {
    
}
| VarDec ASSIGNOP Exp { };

Exp: Exp ASSIGNOP Exp {
    if ($3.read == 1) gen("READ t%d", $1.id);
    else gen("t%d := t%d", $1.id, $3.id);
    $$.read = 0;
}
| Exp AND Exp { } // unused in lab3
| Exp OR Exp { } // unused in lab3
| Exp RELOP Exp {
    $$.true_list = new_list();
    $$.false_list = new_list();
    int *next1 = malloc(sizeof(int)), *next2 = malloc(sizeof(int));
    *next1 = quad + 1, *next2 = quad + 2;
    add_node($$.true_list, next1);
    add_node($$.false_list, next2);
    gen("IF t%d %s t%d GOTO ", $1.id, $2, $3.id);
    gen("GOTO ");
    $$.read = 0;
}
| Exp PLUS Exp {
    $$.id = ++var_id;
    gen("t%d := t%d + t%d", var_id, $1.id, $3.id);
    $$.read = 0;
}
| Exp MINUS Exp {
    $$.id = ++var_id;
    gen("t%d := t%d - t%d", var_id, $1.id, $3.id);
    $$.read = 0;
}
| Exp STAR Exp {
    $$.id = ++var_id;
    gen("t%d := t%d * t%d", var_id, $1.id, $3.id);
    $$.read = 0;
}
| Exp DIV Exp {
    $$.id = ++var_id;
    gen("t%d := t%d / t%d", var_id, $1.id, $3.id);
    $$.read = 0;
}
| LP Exp RP {
    $$.id = $2.id;
    $$.read = 0;
}
| MINUS Exp %prec UMINUS {
    gen("t%d := #0 - t%d", ++var_id, $2.id);
    $$.id = var_id;
    $$.read = 0;
}
| NOT Exp { } // unused in lab3
| ID LP Args RP {
    if (strcmp("write", $1) == 0) gen("WRITE t%d", $3.id);
    else gen("t%d := CALL %s", ++var_id, $1);
    $$.id = var_id;
    $$.read = 0;
}
| ID LP RP {
    if (strcmp($1, "read") != 0) {
        gen("t%d := CALL %s", ++var_id, $1);
        $$.read = 1;
        $$.id = var_id;
        $$.read = 0;
    }
    else $$.read = 1;
}
| Exp LB Exp RB { } // unused in lab3
| Exp DOT ID { } // unused in lab3
| ID {
    $$.id = get_id_by_name(table, $1);
    $$.read = 0;
}
| INT { gen("t%d := #%d", ++var_id, $1); $$.id = var_id; $$.read = 0; }
| FLOAT { gen("t%d := #%f", ++var_id, $1); $$.id = var_id; $$.read = 0; };

Args: Exp COMMA Args {
    gen("ARG t%d", $1.id);
    $$.id = 0;
}
| Exp {
    gen("ARG t%d", $1.id);
    $$.id = $1.id;
};

M: { $$ = quad + 1;};

N: { 
    $$.next_list = new_list();
    int *next = malloc(sizeof(int));
    *next = quad + 1;
    add_node($$.next_list, next);
    gen("GOTO ");
};
%%
