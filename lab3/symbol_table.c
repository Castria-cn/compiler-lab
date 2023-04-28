#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "symbol_table.h"

#define BUF_SIZE (10)

symbol *find_by_name(list *table, char *name) {
    list *ptr = table->next;
    while (ptr) {
        if (strcmp(((symbol*)ptr->val)->symbol_name, name) == 0)
            return ptr->val;
        ptr = ptr->next;
    }
    return NULL; // should not happen in lab 3
}

char *copy_str(char *str) {
    char *ret = malloc(strlen(str));
    strcpy(ret, str);
    return ret;
}

list *new_list() {
    list *head = malloc(sizeof(list));
    head->val = NULL;
    head->next = NULL;
    return head;
}

void add_node(list *head, void *val) {
    list *ptr = head, *new = malloc(sizeof(list));
    while (ptr->next) ptr = ptr->next;
    new->next = NULL;
    new->val = val;
    ptr->next = new;
}

void add_fun(list *table, char *fun_name, int ret_type) {
    symbol *new = malloc(sizeof(symbol));
    new->type = ret_type;
    new->symbol_name = fun_name;
    new->data.fun_info = malloc(sizeof(fun_info));
    new->data.fun_info->args = new_list();
    new->symbol_type = TYPE_FUN;
    add_node(table, new);
}

void add_var(list *table, char *var_name, int type) {
    symbol *new = malloc(sizeof(symbol));
    new->type = type;
    new->symbol_name = var_name;
    new->symbol_type = TYPE_VAR;
    new->data.var_info = malloc(sizeof(var_info));
    new->data.var_info->id = ++var_id;
    add_node(table, new);
}

void add_arg(list *table, char *fun_name, int type, char *arg_name) {
    symbol *target = find_by_name(table, fun_name);
    arg_info *arg = malloc(sizeof(arg_info));
    arg->type = type;
    arg->arg_name = arg_name;
    add_node(target->data.fun_info->args, arg);
}

int get_id_by_name(list *table, char *var_name) {
    list *ptr = table->next;
    while (ptr) {
        symbol *target = ptr->val;
        if (target->symbol_type == TYPE_VAR && strcmp(target->symbol_name, var_name) == 0)
            return target->data.var_info->id;
        ptr = ptr->next;
    }
    return 0;
}

list *copy(list *a) {
    if (a == NULL) return NULL;
    list *node = malloc(sizeof(list));
    node->next = copy(a->next);
    node->val = a->val;
    return node;    
}

list *merge(list *a, list *b) {
    if (!a && !b) return NULL;
    if (!a ^ !b) return !a? b: a;
    // printf("%x, %x\n", a, b);
    list *_a = copy(a), *_b = copy(b);
    list *ptr = _a;
    while (ptr->next) ptr = ptr->next;
    ptr->next = _b->next;
    return _a;
}

char *itoa(int x) {
    char *ret = malloc(BUF_SIZE);
    sprintf(ret, "%d", x);
    return ret;
}

void backpatch(list *lines, int label) {
    if (!lines) return;
    list *ptr = lines->next;
    while (ptr) {
        // printf("backpatch %d with %d\n", *(int*)(ptr->val), label);
        strcat(code[*(int*)(ptr->val)], itoa(label));
        ptr = ptr->next;
    }
}

void gen(const char *format, ...) {
    va_list arg;
    va_start(arg, format);
    
    vsnprintf(code[++quad], COL_LIMIT, format, arg);
    
    va_end(arg);
}

void print_code(char code[LINE_LIMIT][COL_LIMIT]) {
    for (int i = 1; i <= quad; i++) {
        printf("%s\n", code[i]);
    }
}

void print_symbols(list *table) {
    printf("Symbol Table:\n\n");
    list *ptr = table->next;
    while (ptr) {
        symbol *target = ptr->val;
        printf("%s %s", target->type == TYPE_INT? "int": "float", target->symbol_name);
        if (target->symbol_type == TYPE_FUN) {
            fun_info *fun_info = target->data.fun_info;
            list *arg_ptr = fun_info->args->next;
            printf("(");
            while (arg_ptr) {
                arg_info *arg = arg_ptr->val;
                printf("%s %s", arg->type == TYPE_INT? "int": "float", arg->arg_name);
                if (arg_ptr->next) printf(", ");
                arg_ptr = arg_ptr->next;
            }
            printf(")");
        }
        else printf("(t%d)", target->data.var_info->id);
        printf(";\n");
        ptr = ptr->next;
    }
}
