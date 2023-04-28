#include "symbol_table.h"
#include "cc.h"
#include "cc.tab.h"
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <limits.h>

int label_id;
int last_report = 0;
#define TMP_BUF (20)
#define BUFFER_SIZE (1024)

void yyerror(char *s, ...) {
}

void report_error(char *s, int lineno, char *type, ...) {
    if (strcmp(type, "B") == 0) f2p = 1;
    if (lineno == last_report) return;
    printf("Error type %s at Line %d: ", type, lineno);
    va_list args;
    va_start(args, s);
    vprintf(s, args);
    va_end(args);
    printf(".\n");
    last_report = lineno;
}

int starts_with(char *str, char *pattern) {
    int m = strlen(str), n = strlen(pattern);
    if (n > m) return 0;
    for (int i = 0; i < n; i++) {
        if (str[i] != pattern[i]) return 0;
    }
    return 1;
}

void relabel(char code[LINE_LIMIT][COL_LIMIT], int target, int line, int forward) {
    int ptr = 0, label = 0, point, flag = 0;
    while (code[line][ptr] != '\0') {
        if (flag && code[line][ptr] >= '0' && code[line][ptr] <= '9') { label = label * 10 + code[line][ptr] - '0'; }
        if (starts_with(code[line] + ptr, "GOTO ")) {
            ptr += 5;
            flag = 1;
            if (!(code[line][ptr] >= '0' && code[line][ptr] <= '9')) return;
            point = ptr;
            label = label * 10 + code[line][ptr] - '0';
        }
        ptr++;
    }
    if (!flag) return;
    int new_line;
    if (forward) new_line = label + (label < target? 0: -1);
    else new_line = label + (label >= target? 1: 0);
    ptr = 0;
    char buffer[TMP_BUF];
    while (new_line) {
        buffer[ptr++] = new_line % 10 + '0';
        new_line /= 10;
    }
    buffer[ptr] = '\0';
    for (int i = 0, j = ptr - 1; i < j; i++, j--) {
        char tmp = buffer[j];
        buffer[j] = buffer[i];
        buffer[i] = tmp;
    }
    
    strcpy(code[line] + point, buffer);
    code[line][point + strlen(buffer)] = '\0';
}

void forward(char code[LINE_LIMIT][COL_LIMIT], int line) {
    for (int i = line; i <= quad; i++) {
        strcpy(code[i - 1], code[i]);
    }
    quad--;
    for (int i = 1; i <= quad; i++) {// relabel
        relabel(code, line, i, 1);
    }
}

void backward(char code[LINE_LIMIT][COL_LIMIT], int line) {
    for (int i = quad; i >= line; i--) {
        strcpy(code[i + 1], code[i]);
    }
    quad++;
    for (int i = 1; i <= quad; i++) {
        relabel(code, line, i, 0);
    }
}

void insert_label(char code[LINE_LIMIT][COL_LIMIT], int line, int label) {
    backward(code, line);
    char buffer[TMP_BUF];
    // printf("copy label to line %d\n", line);
    sprintf(buffer, "LABEL Label%d :", label);
    strcpy(code[line], buffer);
}

int try_label(char code[LINE_LIMIT][COL_LIMIT], int line) {
    int ptr = 0, flag = 0, label = 0, point;
    while (code[line][ptr] != '\0') {
        if (flag && code[line][ptr] >= '0' && code[line][ptr] <= '9') { label = label * 10 + code[line][ptr] - '0'; }
        if (starts_with(code[line] + ptr, "GOTO ")) {
            ptr += 5;
            flag = 1;
            point = ptr;
            label = label * 10 + code[line][ptr] - '0';
        }
        ptr++;
    }
    if (flag) {
        insert_label(code, label, ++label_id);
        sprintf(code[line] + point, "Label%d", label_id);
    }
    return flag;
}

void postprocess(char code[LINE_LIMIT][COL_LIMIT]) {
    /*
       ARG x
       WRITE x
       ->
       WRITE x
     */
    for (int i = 1; i <= quad; i++) {
         if (starts_with(code[i], "WRITE")) {
             forward(code, i);
         }
    }
    /*
        GOTO X
      
     X: Label xx
     */
    
    for (int i = 1; i <= quad; i++) {
        try_label(code, i);
        // if (try_label(code, i)) {
        // print_code(code);
        // exit(0);
        // }
    }
}

int main(int argc, char **argv) {
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
        quad = 0;
        var_id = 0;
        label_id = 0;
        last_report = 0;
        table = new_list();
        
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
        
        postprocess(code);
        print_code(code);
        print_symbols(table);
        
        fclose(f);
        yylex_destroy();
    }
    return 0;
}
