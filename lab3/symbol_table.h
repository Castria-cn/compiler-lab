#define LINE_LIMIT (200)
#define COL_LIMIT (50)

typedef struct list {
    void *val;
    struct list *next;
} list;

list *table;
int var_id, quad;
char code[LINE_LIMIT][COL_LIMIT];

enum symbol_type { TYPE_VAR, TYPE_FUN };
enum data_type { TYPE_INT, TYPE_FLOAT };

typedef struct {
    int type;
    char *arg_name;
} arg_info;

typedef struct {
    int id;
} var_info;

typedef struct {
    list *args; // arg_info list
} fun_info;

typedef struct {
    int type; // for function, type is for type of its return value
    int symbol_type; // TYPE_VAR or TYPE_FUN
    char *symbol_name;
    union {
        var_info *var_info; // for extension
        fun_info *fun_info; // for extension
    } data;
} symbol;

symbol *find_by_name(list *table, char *name);

char *copy_str(char *str);

list *new_list();

void add_node(list *head, void *val);

void add_fun(list *table, char *fun_name, int ret_type);

void add_var(list *table, char *var_name, int type);

void add_arg(list *table, char *fun_name, int type, char *arg_name);

void print_symbols(list *table);

int get_id_by_name(list *table, char *var_name);

void gen(const char *format, ...);

void backpatch(list *lines, int label);

list *copy(list *a);

list *merge(list *a, list *b);
