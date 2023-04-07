#include "cc.h"
#include "cc.tab.h"
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <limits.h>

#define BUFFER_SIZE (1024)

/**
 * Returns a new linked list.
 */
 
struct listnode *new_list() {
    struct listnode *head = malloc(sizeof(struct listnode));
    head->value = 0;
    return head;
}

void yyerror(char *s, ...) {
}

void report_error(char *s, int lineno) {
    f2p = 1;
    // if (latest_err == yylineno) return;
    printf("Error type B at Line %d: %s.\n", lineno, s);
}

int get_length(struct listnode *head) {
    return (int)(long)(head->value);
}

/**
 * Add a node given a linked list's head.
 */
void add_node(struct listnode *head, data value) {
    struct listnode *ptr = head;
    while (ptr->next != NULL) ptr = ptr->next;
    ptr->next = malloc(sizeof(struct listnode));
    ptr->next->value = value;
    ptr->next->next = NULL;
    head->value++;
}

struct listnode *make_list(int num, ...) {
    va_list arg_ptr;
    struct listnode *ret = new_list();
    va_start(arg_ptr, num);
    
    int i;
    data value;
    for (i = 0; i < num; i++) {
        value = va_arg(arg_ptr, data);
        add_node(ret, value);
    }
    
    va_end(arg_ptr);
    
    return ret;
}

struct ast *make_ast(char* type, struct listnode *children) {
    if (f2p) return NULL; // give up making ast if already failed to parse
    struct ast *ret = malloc(sizeof(struct ast));
    ret->type = type;
    ret->value = NULL;
    ret->children = children;
    ret->lnum = INT_MAX;
    
    // calculate the line number of grammar unit
    struct listnode *ptr = children->next;
    while (ptr != NULL) {
        ret->lnum = (((struct ast*)(ptr->value))->lnum < ret->lnum)? ((struct ast*)(ptr->value))->lnum: ret->lnum;
        ptr = ptr->next;
    }
    return ret;
}

struct ast *make_int(int i, int lnum) {
    struct ast *ret = malloc(sizeof(struct ast));
    ret->type = "INT";
    ret->value = malloc(sizeof(int));
    *((int*)(ret->value)) = i;
    ret->children = NULL;
    ret->lnum = lnum;
    return ret;
}

struct ast *make_float(float f, int lnum) {
    struct ast *ret = malloc(sizeof(struct ast));
    ret->type = "FLOAT";
    ret->value = malloc(sizeof(float));
    *((float*)(ret->value)) = f;
    ret->children = NULL;
    ret->lnum = lnum;
    return ret;
}

struct ast *make_id(char *s, int lnum) {
    struct ast *ret = malloc(sizeof(struct ast));
    ret->type = "ID";
    
    ret->value = malloc(strlen(s) + 1);
    strcpy(ret->value, s);
    
    ret->children = NULL;
    ret->lnum = lnum;
    return ret;
}

struct ast *make_type(char *s, int lnum) {
    struct ast *ret = malloc(sizeof(struct ast));
    ret->type = "TYPE";
    
    ret->value = malloc(strlen(s) + 1);
    strcpy(ret->value, s);
    
    ret->children = NULL;
    ret->lnum = lnum;
    return ret;
}

struct ast *make_terminal(char *type, int lnum) {
    struct ast *ret = malloc(sizeof(struct ast));
    ret->type = type;
    ret->children = NULL;
    ret->lnum = lnum;
    return ret;
}

int is_terminal(struct ast *now) {
    int i, n = strlen(now->type);
    for (i = 0; i < n; i++) {
        if (now->type[i] < 'A' || now->type[i] > 'Z') return 0;
    }
    return 1;
}

int generates_epsilon(struct ast *now) {
    return now->children && get_length(now->children) == 0;
}

void print_node(struct ast *now, int indent) {
    int i;
    if (generates_epsilon(now)) return;
    for(i = 0; i < indent; i++) printf(" ");
    if (now->value != NULL) {
        if (strcmp(now->type, "INT") == 0) printf("INT: %d (%d)\n", *(int*)(now->value), now->lnum);
        if (strcmp(now->type, "FLOAT") == 0) printf("FLOAT: %f (%d)\n", *(float*)(now->value), now->lnum);
        if (strcmp(now->type, "ID") == 0) printf("ID: %s (%d)\n", (char*)now->value, now->lnum);
        if (strcmp(now->type, "TYPE") == 0) printf("TYPE: %s (%d)\n", (char*)now->value, now->lnum);
    }
    else printf("%s (%d)\n", now->type, now->lnum);
    // printf(", line=%d]\n", now->lnum);
}

void print_ast(struct ast *now, int depth) {
    print_node(now, depth * 2);

    if (now->children == NULL) {
        return;
    }
    struct listnode *ptr = now->children->next;
    while (ptr != NULL) {
        print_ast(ptr->value, depth + 1);
        ptr = ptr->next;
    }
}
int main(int argc, char **argv) {
    // freopen("result.txt", "w", stdout);
    if (argc < 2) {
        printf("must input test file directory!\n");
        return 0;
    }
    if (argc == 3) {
        if (strcmp(argv[2], "1") == 0)
            freopen("result.txt", "w", stdout);
    }
    char test_dir[BUFFER_SIZE] = "ls ", buffer[BUFFER_SIZE], path[BUFFER_SIZE];
    strcat(test_dir, argv[1]);
    FILE *output = popen(test_dir, "r");
    while (fgets(buffer, sizeof(buffer), output) != NULL) {
        f2p = 0;
    	int n = strlen(buffer);
    	if (buffer[n - 1] == '\n') buffer[n - 1] = '\0';
    	strcpy(path, argv[1]);
    	strcat(path, buffer);
    	printf("----------------------------------------\n");
    	printf("%s\n", path);
    	printf("----------------------------------------\n");
        FILE *f = fopen(path, "r");
        yyrestart(f);
        yyparse();
        
        if (!f2p) print_ast(root, 0);
        
        fclose(f);
        yylex_destroy();
    }
    return 0;
}
