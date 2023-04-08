#include "symbol_table.h"
#include "cc.h"
#include "cc.tab.h"
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <limits.h>

#define BUFFER_SIZE (1024)

void yyerror(char *s, ...) {
}

void report_error(char *s, int lineno, char *type) {
    if (strcmp(type, "B") == 0) f2p = 1;
    printf("Error type %s at Line %d: %s.\n", type, lineno, s);
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
        
        // memory leak!
        table = new_list();
        struct_table = new_list();
        
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
        if (!f2p) {
            print_table(table);
        }
        fclose(f);
        yylex_destroy();
    }
    return 0;
}
