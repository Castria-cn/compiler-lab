#include <stddef.h>
#include "symbol_table.h"

struct listnode *new_list() {
    struct listnode *head = malloc(sizeof(struct listnode));
    head->value = 0;
    head->next = NULL;
    return head;
}

void add_node(struct listnode *head, data value) {
    struct listnode *ptr = head;
    while (ptr->next != NULL) ptr = ptr->next;
    ptr->next = malloc(sizeof(struct listnode));
    ptr->next->value = value;
    ptr->next->next = NULL;
    head->value++;
}

int has_item(struct listnode *T, char *s) {
	struct listnode *ptr = T;
	while (ptr->next != NULL) {
		ptr = ptr->next;
		if (strcmp(((struct table_item*)(ptr->value))->symbol_name, s) == 0) return 1;
	}
	return 0;
}

int insert_var(struct listnode *T, char *s, struct struct_info *type, struct listnode *shape) {
	if (has_item(T, s)) {
		printf("symbol %s already exists!\n", s);
		return 0;
	}
	struct table_item *t = malloc(sizeof(struct table_item));
	t->type = VAR;
	t->symbol_name = malloc(strlen(s));
	strcpy(t->symbol_name, s);
	t->data.var_info.vtype = type;
	t->data.var_info.shape = shape;
	add_node(T, t);
	return 1;
}

int insert_fun(struct listnode *T, char *s, struct struct_info *type) {
	if (has_item(T, s)) {
		printf("symbol %s already exists!\n", s);
		return 0;
	}
	struct table_item *t = malloc(sizeof(struct table_item));
	t->type = FUN;
	t->symbol_name = malloc(strlen(s));
	strcpy(t->symbol_name, s);
	struct fun_info *fun_info = malloc(sizeof(struct fun_info));
	fun_info->ret_vtype = type;
	fun_info->head = new_list();
	t->data.fun_info = fun_info;
	add_node(T, t);
	return 1;
}

int insert_arg(struct listnode *T, char *fun_name, struct struct_info *type, char *arg_name, struct listnode *shape) {
	if (!has_item(T, fun_name)) {
		printf("function name does not exist!\n");
		return 0;
	}
	struct listnode *ptr = T;
	while (ptr->next != NULL) {
		ptr = ptr->next;
		if (strcmp(((struct table_item*)(ptr->value))->symbol_name, fun_name) == 0) {
			// check if there is already an arg named arg_name
			struct listnode *arg_ptr = ((struct table_item*)(ptr->value))->data.fun_info->head;
			while (arg_ptr->next != NULL) {
				arg_ptr = arg_ptr->next;
				if (strcmp(((struct arg_info*)(arg_ptr->value))->arg_name, arg_name) == 0) {
					printf("function %s already has an arg named %s!\n", fun_name, arg_name);
					return 0;
				}
			}
			struct table_item *item = ptr->value;
			struct arg_info *arg = malloc(sizeof(struct arg_info));
			arg->arg_vtype = type;
			arg->arg_name = malloc(strlen(arg_name));
			arg->shape = shape;
			strcpy(arg->arg_name, arg_name);
			add_node(item->data.fun_info->head, arg);
		}
	}
	return 1;
}

struct struct_info *insert_struct(struct listnode *T, char *opt_name) {
	if (opt_name != NULL) {
		struct listnode *ptr = T;
		while (ptr->next != NULL) {
			ptr = ptr->next;
			// printf("structs: %s\n", ((struct struct_info*)(ptr->value))->opt_tag);
			if (strcmp(((struct struct_info*)(ptr->value))->opt_tag, opt_name) == 0) {
				printf("struct tag %s already exists!\n", opt_name);
				return NULL;
			}
		}
	}
	struct struct_info *ret = malloc(sizeof(struct struct_info));
	ret->fields = new_list();
	ret->opt_tag = opt_name;
	add_node(T, ret);
	return ret;
}

int insert_field(struct struct_info *struct_info, char *field_name, struct struct_info *type, struct listnode *shape) {
	struct listnode *ptr = struct_info->fields;
	while (ptr->next != NULL) {
		ptr = ptr->next;
		if (strcmp(((struct field_info*)(ptr->value))->field_name, field_name) == 0) {
			printf("struct field name exists!\n");
			return 0;
		}
	} 
	
	struct field_info *node = malloc(sizeof(struct field_info));
	node->field_name = malloc(strlen(field_name));
	strcpy(node->field_name, field_name);
	node->type = type;
	node->shape = shape;
	add_node(struct_info->fields, node);
	return 1;
}

struct struct_info *find_struct_by_name(struct listnode *struct_table, char *s) {
	if (strcmp(s, "int") == 0) return INT_TYPE;
	if (strcmp(s, "float") == 0) return FLOAT_TYPE;
	struct listnode *ptr = struct_table;
	while (ptr->next != NULL) {
		ptr = ptr->next;
		if (strcmp(((struct struct_info*)(ptr->value))->opt_tag, s) == 0) {
			return (struct struct_info*)(ptr->value);
		}
	}
	return NO_SUCH_STRUCT;
}

int has_field(struct struct_info *struct_info, char *s) {
    struct listnode *ptr = struct_info->fields;
    while (ptr->next != NULL) {
        ptr = ptr->next;
        if (strcmp(((struct field_info*)(ptr->value))->field_name, s) == 0) 
            return 1;
    }
    return 0;
}

struct table_item *get_item_by_name(struct listnode *table, char *s) {
    struct listnode *ptr = table;
    while (ptr->next != NULL) {
        ptr = ptr->next;
        if (strcmp(((struct table_item*)(ptr->value))->symbol_name, s) == 0)
            return ((struct table_item*)(ptr->value));
    }
    
    return NO_SUCH_STRUCT;
}

struct struct_info *get_type_by_name(struct listnode *table, char *s) {
    struct listnode *ptr = table;
    while (ptr->next != NULL) {
        ptr = ptr->next;
        if (strcmp(((struct table_item*)(ptr->value))->symbol_name, s) == 0)
            return ((struct table_item*)(ptr->value))->data.var_info.vtype;
    }
    return NO_SUCH_STRUCT;
}

struct field_info *get_field_by_name(struct struct_info *struct_info, char *s) {
    struct listnode *ptr = struct_info->fields;
    struct field_info *ret = NULL;
    while (ptr->next != NULL) {
        ptr = ptr->next;
        if (strcmp(((struct field_info*)(ptr->value))->field_name, s) == 0) {
            ret = ptr->value;
            break;
        }
    }
    return ret;
}
void print_vinfo(struct struct_info *f) {
	switch((unsigned long long)f) {
		case INT_TYPE:
			printf("INT\n");
			break;
		case FLOAT_TYPE:
			printf("FLOAT\n");
			break;
		default:
			print_sinfo(f, 0);

	}
}

void print_finfo(struct fun_info *f) {
	struct listnode *ptr = f->head;
	printf("(");
	while (ptr->next != NULL) {
		ptr = ptr->next;
		struct arg_info *arg = ptr->value;
		switch((unsigned long long)arg->arg_vtype) {
		case INT_TYPE:
			printf("%s: INT", arg->arg_name);
			break;
		case FLOAT_TYPE:
			printf("%s: FLOAT", arg->arg_name);
			break;
		default:
			printf("%s: %s", arg->arg_name, arg->arg_vtype->opt_tag);
			break;
		}
		print_shape(arg->shape);
		if (ptr->next != NULL) printf(", ");
	}
	printf(") -> ");
	
	switch((unsigned long long)f->ret_vtype) {
		case INT_TYPE:
			printf("INT\n");
			break;
		case FLOAT_TYPE:
			printf("FLOAT\n");
			break;
		default:
			if (f->ret_vtype->opt_tag == NULL) printf("Anonymous struct\n");
			else printf("%s\n", f->ret_vtype->opt_tag);
			break;
	}
}

void print_sinfo(struct struct_info *f, int recalled) {
	if ((unsigned long long)f == INT_TYPE) {
		printf("INT\n");
		return;
	}
	else if ((unsigned long long)f == FLOAT_TYPE) {
		printf("FLOAT\n");
		return;
	}
	
	if (f->opt_tag == NULL) printf("Anonymous struct ");
	else printf("%s ", f->opt_tag);
	if (recalled) {
		printf("\n");
		return;
	}
	printf("{\n");
	struct listnode *ptr = f->fields;
	while (ptr->next != NULL) {
		ptr = ptr->next;
		printf("  %s: ", ((struct field_info*)(ptr->value))->field_name);
		print_sinfo(((struct field_info*)(ptr->value))->type, 1);
		if (((struct field_info*)(ptr->value))->shape->value) { printf("  >> shape: "); print_shape(((struct field_info*)(ptr->value))->shape); printf("\n"); }
	}
	printf("}\n");
}

void print_item(struct table_item *t) {
	printf("- %s: ", t->symbol_name);
	switch (t->type) {
		case VAR:
			print_vinfo(t->data.var_info.vtype);
			if ((t->data.var_info.shape)->value) {
	    			printf(">> shape: ");
	    			print_shape((t->data).var_info.shape);
	    			printf("\n");
	    		}
			break;
		case FUN:
			print_finfo(t->data.fun_info);
			break;
		case STRUCT_TYPE:
			print_sinfo(t->data.struct_info, 0);
			break;
	}
}

void print_shape(struct listnode *shape) {
    struct listnode *ptr = shape;
    if (ptr->next == NULL) return;
    printf("(");
    while (ptr->next != NULL) {
        ptr = ptr->next;
        printf("%d", *(int*)(ptr->value));
        if (ptr->next != NULL) printf(", ");
    }
    printf(")");
}

void print_table(struct listnode *T) {
	struct listnode *ptr = T;
	if (ptr->next == NULL) {
	    printf("No symbols.\n");
	}
	while (ptr->next != NULL) {
		ptr = ptr->next;
		print_item((struct table_item*)ptr->value);
	}
}
