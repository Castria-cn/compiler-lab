%{
#include <stdio.h>
#include <stdlib.h>
#include "cc.h"
#include "symbol_table.h"

int in_struct = 0, arg_mismatched = 0, using_struct = 0;
char *arg_name, *arg_type, *fun_name, *type;
struct struct_info *struct_ptr;
struct table_item *fun_calling;
struct listnode *name_list, *type_list, *shape_list, *shapes, *matching_arg;
%}
/*
several kinds of terminal symbol:
1. int
2. float
3. id
else the symbol is non-terminal, represented as AST
*/
%union {
    char *content;
    int i;
    float d;
    char *id;
    char *type;
    struct {
        struct struct_info *type;
        int dim;
        int assignable;
    } exp;
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

%type <content> Program ExtDefList ExtDef ExtDecList Specifier StructSpecifier OptTag Tag VarDec FunDec VarList ParamDec CompSt StmtList Stmt DefList Def DecList Dec Args
%type <exp> Exp
%type <id> RELOP
%%
Program: {shape_list = new_list(); }ExtDefList {
};

ExtDefList: {}
| ExtDef ExtDefList {
};

ExtDef: Specifier ExtDecList SEMI {
    struct listnode *ptr = name_list, *ptr2 = shapes;
    while (ptr->next != NULL) {
        ptr = ptr->next;
        ptr2 = ptr2->next;
        if (find_struct_by_name(struct_table, type) == NO_SUCH_STRUCT) {
            report_error("Undeclared struct", @1.first_line, "17");
            continue;
        }
        if (using_struct) {
            if (has_tag(struct_table, ptr->value) || has_item(table, ptr->value)) report_error("Variable name \"%s\" already used", @1.first_line, "3", ptr->value);
            else insert_var(table, ptr->value, struct_ptr, ptr2->value);
        }
        else {
            if (has_tag(struct_table, ptr->value) || has_item(table, ptr->value)) report_error("Variable name \"%s\" already used", @1.first_line, "3", ptr->value);
            else insert_var(table, ptr->value, find_struct_by_name(struct_table, type), ptr2->value);
        }
    }
    using_struct = 0;
    name_list = new_list();
}
| Specifier SEMI {}
| Specifier FunDec { 
    if (insert_fun(table, fun_name, struct_ptr) == 0) {
        report_error("Function redeclaration", @1.first_line, "4");
    }
    if (type_list == NULL) type_list = new_list();
    struct listnode *ptr1 = type_list, *ptr2 = name_list, *ptr3 = shapes;
    while (ptr1->next != NULL) {
        ptr1 = ptr1->next;
        ptr2 = ptr2->next;
        ptr3 = ptr3->next;
        print_shape(ptr3->value);
        if (insert_arg(table, fun_name, find_struct_by_name(struct_table, ptr1->value), ptr2->value, ptr3->value) == 0) {
            report_error("Argument redeclaration", @1.first_line, "3");
        }
        else {
            if (has_tag(struct_table, ptr2->value) || has_item(table, ptr2->value)) report_error("Variable name \"%s\" already used", @1.first_line, "3", ptr2->value);
            else insert_var(table, ptr2->value, find_struct_by_name(struct_table, ptr1->value), ptr3->value);
        }
    }
    type_list = new_list();
    name_list = new_list();
} CompSt { }
| Specifier error SEMI { report_error("ExtDef error; Sync with SEMI", @3.first_line, "B"); }
| Specifier error { report_error("ExtDef error; Missing ';'?", @2.first_line, "B"); };

ExtDecList: VarDec { add_node(shapes, shape_list); shape_list = new_list(); }
| VarDec { add_node(shapes, shape_list); shape_list = new_list(); } COMMA ExtDecList {  };

Specifier: TYPE { type = malloc(strlen($1)); strcpy(type, $1); }
| StructSpecifier { using_struct = 1; };

StructSpecifier: STRUCT OptTag { 
    in_struct = 1;
    if ((struct_ptr = insert_struct(struct_table, $2)) == NULL || has_item(table, $2)) {
        report_error("Redeclaration struct tag", @1.first_line, "16");
    }
} LC DefList RC {
    in_struct = 0;
    name_list = new_list();
}
| STRUCT Tag {  };

OptTag: {  }
| ID {  };

Tag: ID { type = malloc(strlen($1)); strcpy(type, $1); };

VarDec: ID {
    arg_name = malloc(strlen($1));
    strcpy(arg_name, $1);
    if (name_list == NULL) name_list = new_list();
    if (shapes == NULL) shapes = new_list();
    add_node(name_list, arg_name); 
}
| VarDec LB INT RB { if (shape_list == NULL) shape_list = new_list(); int *shape = malloc(sizeof(int)); *shape = $3; add_node(shape_list, shape); }
| error RB { report_error("VarDec error; Sync with RB", @2.first_line, "B"); };

FunDec: ID LP VarList RP { fun_name = malloc(strlen($1)); strcpy(fun_name, $1); }
| ID LP RP { fun_name = malloc(strlen($1)); strcpy(fun_name, $1); }
| error RP { report_error("FunDec error; Sync with RP", @2.first_line, "B"); };

VarList: ParamDec { add_node(shapes, shape_list); shape_list = new_list(); } COMMA VarList {  }
| ParamDec error VarList { report_error("VarList error; Sync with VarList", @1.first_line, "B"); }
| ParamDec { add_node(shapes, shape_list); shape_list = new_list(); };

ParamDec: Specifier VarDec {
    arg_type = malloc(strlen(type));
    strcpy(arg_type, type);
    
    if (type_list == NULL) type_list = new_list();
    if (name_list == NULL) name_list = new_list();
    if (shapes == NULL) shapes = new_list();
    add_node(type_list, arg_type);
};
CompSt: LC DefList StmtList RC { }
| error RC { report_error("CompSt error; Sync with RC", @2.first_line, "B"); };

StmtList: {  }
| Stmt StmtList {  };

Stmt: Exp SEMI {  }
| CompSt {  }
| RETURN Exp SEMI {
    if (struct_ptr != $2.type || $2.dim != 0) report_error("Return type differs from function definition", @1.first_line, "8");
}
| IF LP Exp RP Stmt %prec LOWER_THAN_ELSE {  }
| IF LP Exp RP Stmt ELSE Stmt { }
| WHILE LP Exp RP Stmt {  } 
| error SEMI { report_error("Stmt error; Sync with SEMI", @2.first_line, "B"); }
| error ELSE { report_error("Stmt error; Sync with ELSE", @1.first_line, "B"); }
| WHILE LP error RP Stmt { report_error("Stmt error; Wrong while exp", @2.first_line, "B");}
| IF LP error RP Stmt { report_error("Stmt error; Wrong if exp", @2.first_line, "B"); };

DefList: {  }
| Def DefList {
};

Def: Specifier DecList SEMI {
    struct listnode *ptr = name_list, *ptr2 = shapes;
    while (ptr->next != NULL) {
        ptr = ptr->next;
        ptr2 = ptr2->next;
        if (find_struct_by_name(struct_table, type) == NO_SUCH_STRUCT) {
            report_error("Undeclared struct", @1.first_line, "17");
            continue;
        }
        if (in_struct) {
            if (insert_field(struct_ptr, ptr->value, find_struct_by_name(struct_table, type), ptr2->value) == 0) {
                report_error("Redeclaration field", @1.first_line, "15");
            }
        }
        else {
            if (has_tag(struct_table, ptr->value) || has_item(table, ptr->value)) report_error("Variable name \"%s\" already used", @1.first_line, "3", ptr->value);
            else insert_var(table, ptr->value, find_struct_by_name(struct_table, type), ptr2->value);
        }
    }
    name_list = new_list();
    shapes = new_list();
    shape_list = new_list();
}
| Specifier DecList error { report_error("Def error", @2.first_line, "B"); }
| Specifier error SEMI { report_error("Def error; DecList error", @3.first_line, "B"); };

DecList: Dec {
    add_node(shapes, shape_list);
}
| Dec { add_node(shapes, shape_list); shape_list = new_list(); } COMMA DecList { };
Dec: VarDec {
    
}
| VarDec ASSIGNOP Exp { };

Exp: Exp ASSIGNOP Exp {
    if ($1.assignable == 0) report_error("Assigning a right value", @1.first_line, "6");
    
    // assign between dim 0 is allowed.
    else if ($1.type != $3.type || $1.dim != $3.dim || $1.dim > 0) report_error("Assign expression mismatch", @1.first_line, "5");
    else {
        $$.type = $3.type;
        $$.dim = 0;
    }
    $$.assignable = 0;
}
| Exp AND Exp {
    if ($1.type != $3.type) { report_error("Operation type mismatch: &&", @1.first_line, "7"); }
    else if (!($1.type <= FLOAT && $1.dim == $3.dim && $1.dim == 0)) {
        report_error("Operation type mismatch", @1.first_line, "7");
    }
    else {
        $$.type = INT_TYPE;
        $$.dim = $1.dim;
    }
    $$.assignable = 0;
}
| Exp OR Exp {
    if ($1.type != $3.type) { report_error("Operation type mismatch: ||", @1.first_line, "7"); }
    else if (!($1.type <= FLOAT && $1.dim == $3.dim && $1.dim == 0)) {
        report_error("Operation type mismatch", @1.first_line, "7");
    }
    else {
        $$.type = INT_TYPE;
        $$.dim = $1.dim;
    }
    $$.assignable = 0;
}
| Exp RELOP Exp {
    if ($1.type != $3.type) { report_error("Operation type mismatch: %s", @1.first_line, "7", $2); }
    else if (!($1.type <= FLOAT && $1.dim == $3.dim && $1.dim == 0)) {
        report_error("Operation type mismatch", @1.first_line, "7");
    }
    else {
        $$.type = INT_TYPE;
        $$.dim = $1.dim;
    }
    $$.assignable = 0;
}
| Exp PLUS Exp {
    if ($1.type != $3.type) { report_error("Operation type mismatch: +", @1.first_line, "7", $1.type, $3.type); }
    else if (!($1.type <= FLOAT && $1.dim == $3.dim && $1.dim == 0)) {
        report_error("Operation type mismatch", @1.first_line, "7");
    }
    else {
        $$.type = $1.type;
        $$.dim = $1.dim;
    }
    $$.assignable = 0;
}
| Exp MINUS Exp {
    if ($1.type != $3.type) { report_error("Operation type mismatch: -", @1.first_line, "7"); }
    else if (!($1.type <= FLOAT && $1.dim == $3.dim && $1.dim == 0)) {
        report_error("Operation type mismatch", @1.first_line, "7");
    }
    else {
        $$.type = $1.type;
        $$.dim = $1.dim;
    }
    $$.assignable = 0;
}
| Exp STAR Exp {
    if ($1.type != $3.type) { report_error("Operation type mismatch: *", @1.first_line, "7"); }
    else if (!($1.type <= FLOAT && $1.dim == $3.dim && $1.dim == 0)) {
        report_error("Operation type mismatch", @1.first_line, "7");
    }
    else {
        $$.type = $1.type;
        $$.dim = $1.dim;
    }
    $$.assignable = 0;
}
| Exp DIV Exp {
    if ($1.type != $3.type) { report_error("Operation type mismatch: /", @1.first_line, "7"); }
    else if (!($1.type <= FLOAT && $1.dim == $3.dim && $1.dim == 0)) {
        report_error("Operation type mismatch", @1.first_line, "7");
    }
    else {
        $$.type = $1.type;
        $$.dim = $1.dim;
    }
    $$.assignable = 0;
}
| LP Exp RP {
    $$.type = $2.type;
    $$.dim = $2.dim;
    $$.assignable = $2.assignable;
}
| MINUS Exp %prec UMINUS {
    if (!($2.type <= FLOAT)) report_error("Operation type mismatch: -", @1.first_line, "7");
    else {
        $$.type = $2.type;
        $$.dim = $2.dim;
    }
    $$.assignable = 0;
}
| NOT Exp {
    if (!($2.type <= FLOAT)) report_error("Operation type mismatch: -", @1.first_line, "7");
    else {
        $$.type = $2.type;
        $$.dim = $2.dim;
    }
    $$.assignable = 0;
}
| ID LP { if (has_item(table, $1) == 0) {report_error("Function \"%s\" undeclared", @1.first_line, "2", $1); matching_arg = NULL;} else { arg_mismatched = 0; fun_calling = get_item_by_name(table, $1); matching_arg = fun_calling->data.fun_info->head->next;}} Args RP {
    if (has_item(table, $1) == 0) report_error("Function undeclared", @1.first_line, "2");
    else if (get_item_by_name(table, $1)->type != FUN) report_error("Calling a non-function identifier", @1.first_line, "11");
    else if (matching_arg != NULL) report_error("Argument number mismatch", @1.first_line, "9");
    else {
        $$.type = fun_calling->data.fun_info->ret_vtype;
        $$.dim = 0;
    }
    $$.assignable = 0;
}
| ID LP { if (has_item(table, $1) == 0) {report_error("Function \"%s\" undeclared", @1.first_line, "2", $1); matching_arg = NULL;} else { arg_mismatched = 0; fun_calling = get_item_by_name(table, $1); matching_arg = NULL;}} RP {
    if (has_item(table, $1) == 0) report_error("Function undeclared", @1.first_line, "2");
    else if (get_item_by_name(table, $1)->type != FUN) report_error("Calling a non-function identifier", @1.first_line, "11");
    else if (fun_calling->data.fun_info->head->value) report_error("Argument number mismatch", @1.first_line, "9");
    else {
        
        $$.type = fun_calling->data.fun_info->ret_vtype;
        $$.dim = 0;
    }
    $$.assignable = 0;
}
| Exp LB Exp RB {
    if ($1.dim == 0) report_error("Indexing a non-array variable", @1.first_line, "10");
    else if ($3.type != INT_TYPE) report_error("Non-int appears in index", @1.first_line, "12");
    $$.type = $1.type;
    $$.dim = $1.dim - 1;
    $$.assignable = $1.assignable;
}
| Exp DOT ID {
    if (($1.dim != 0) || ($1.type < NO_SUCH_STRUCT)) { report_error("Using DOT operator to a non-struct", @1.first_line, "13");}
    else if (!has_field($1.type, $3)) report_error("Undeclared struct field", @1.first_line, "14");
    else {
    	struct field_info *field = get_field_by_name(struct_ptr, $3);
    	if (field == NULL) { printf("!!\n"); $$.type = INT_TYPE; /* set to INT_TYPE */ $$.dim = 0; $$.assignable = 0;}
    	else {
    	    $$.type = field->type;
    	    $$.dim = field->shape->value;
    	    $$.assignable = 1;
    	}
    }
}
| ID { 
    if (has_item(table, $1) == 0) { report_error("Variable \"%s\" undeclared", @1.first_line, "1", $1);  $$.type = INT_TYPE; }
    else {
        struct table_item *item = get_item_by_name(table, $1);
        if (item->type != VAR) {
            $$.type = NOT_A_VAR;
            $$.dim = 0;
        }
        else {
            $$.type = item->data.var_info.vtype;
            $$.dim = item->data.var_info.shape->value;
        }
    }
    $$.assignable = 1;
}
| INT { $$.type = INT_TYPE; $$.dim = 0; $$.assignable = 0; }
| FLOAT { $$.type = FLOAT_TYPE; $$.dim = 0; $$.assignable = 0; };

Args: Exp COMMA Args {
    if (matching_arg == NULL) { if (!arg_mismatched) report_error("Argument number mismatch", @1.first_line, "9"); arg_mismatched = 1; }
    else if (((struct arg_info*)(matching_arg->value))->arg_vtype != $1.type) { if (!arg_mismatched) report_error("Argument type mismatch", @1.first_line, "9"); arg_mismatched = 1; matching_arg = matching_arg->next; }
    else {
        matching_arg = matching_arg->next;
    }
}
| Exp {
   if (matching_arg == NULL && !arg_mismatched) { if (!arg_mismatched) report_error("Argument number mismatch", @1.first_line, "9"); arg_mismatched = 1; }
   else if (((struct arg_info*)(matching_arg->value))->arg_vtype != $1.type) { if (!arg_mismatched) report_error("Argument type mismatch", @1.first_line, "9"); arg_mismatched = 1; matching_arg = matching_arg->next; }
   else {
       matching_arg = matching_arg->next;
   }
};

%%
