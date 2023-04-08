typedef void *data;
#define NO_SUCH_STRUCT (2)
#define NOT_A_VAR (3)

struct listnode {
    data value;
    struct listnode *next;
};

struct listnode *table;
struct listnode *struct_table;

enum vtype { INT_TYPE, FLOAT_TYPE, STRUCT_TYPE };
enum item_type { VAR, FUN, STRUCT_DEF }; // definition

/**
 * The argument info of a function.
 * - arg_vtype: the value type of the argument.
 * - arg_name: the name of the argument.
*/
struct arg_info {
	struct struct_info *arg_vtype;
	struct listnode *shape;
	char *arg_name;
};

/**
 * The function info.
 * - ret_vtype: value type of the return value.
 * - head: head node of the argument list.
*/
struct fun_info {
	struct struct_info *ret_vtype; // type of the return value
	struct listnode *head; // arglists, each node maintains a pointer to arg_info(when pointer value == INT/FLOAT, base type)
};

/**
 * The struct info. Also presents the base type: INT(0) and FLOAT(1).
 * - opt_tag: The optional tag of the struct declaration. NULL if anonymous.
 * - fields: head node of the field list.
*/
struct struct_info {
	char *opt_tag;
	struct listnode *fields;
};

struct field_info {
	char *field_name;
	struct listnode *shape;
	struct struct_info *type;
};

struct table_item {
	enum item_type type; // -> {VAR, FUN, STRUCT}
	char *symbol_name;
	union {
		struct {
		    struct struct_info *vtype; // for VAR -> {INT, FLOAT, STRUCT}
		    struct listnode *shape;
		} var_info;
		struct fun_info *fun_info; // for FUN
		struct struct_info *struct_info; // for STRUCT
	} data;
};

/**
 * Insert a variable into the table T.
 * - char *s: name of the variable
 * - id_type type: type of the variable
 * Returns 1 if succeed, otherwise returns 0(when the item already exists). 
 */
int insert_var(struct listnode *T, char *s, struct struct_info *type, struct listnode *shape);

/**
 * Insert a function into the table T.
 * - char *s: name of the function
 * - id_type type: return type of the function
 * Returns 1 if succeed, otherwise returns 0 (when the item already exists). 
 */
int insert_fun(struct listnode *T, char *s, struct struct_info *type);

/**
 * Add an argument to the function fun_name.
 * - char *fun_name: name of the function
 * - struct struct_info *type: type of the argument.
 * Returns 1 if succeed, otherwise returns 0 (when the argument already exists).
 */
int insert_arg(struct listnode *T, char *fun_name, struct struct_info *type, char *arg_name, struct listnode *shape);

/**
 * Add a struct to the table.
 * - opt_name: the optional tag of struct. 
 * Returns NULL if opt_name already exists, otherwise return the struct pointer.
 */
struct struct_info *insert_struct(struct listnode *T, char *opt_name);

/**
 * Add a field to a struct.
 * - field_name: the name of the field.
 * - type: the pointer to the type.
 * Returns 1 if succeed; else returns 0.
*/
int insert_field(struct struct_info *struct_info, char *field_name, struct struct_info *type, struct listnode *shape);

/**
 * To check if there is a variable called s in symbol table T.
 * Returns 1 if s already exists else 0.
*/
int has_item(struct listnode *T, char *s);

/**
 * Find the struct_info pointer whose opt_tag(typename) is s.
 * Returns NULL if there is no such a struct declaration, else the struct_info pointer.
*/
struct struct_info *find_struct_by_name(struct listnode *struct_table, char *s);

/**
 * Check if there is a field s in struct_info.
 * Returns 1 if there is, else 0.
 */
int has_field(struct struct_info *struct_info, char *s);

struct listnode *new_list();

/**
 * Get the type of a variable.
 */
struct struct_info *get_type_by_name(struct listnode *table, char *s);

/**
 * Get the symbol table item by its name.
 */
struct table_item *get_item_by_name(struct listnode *table, char *s);

struct field_info *get_field_by_name(struct struct_info *struct_info, char *s);
