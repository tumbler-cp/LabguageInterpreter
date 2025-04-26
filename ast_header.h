/* ast_header.h */
#ifndef AST_HEADER_H
#define AST_HEADER_H

typedef enum {
    NODE_NUM,
    NODE_VAR,
    NODE_PLUS,
    NODE_MINUS,
    NODE_MUL,
    NODE_DIV,
    NODE_MOD,
    NODE_UMINUS,
    NODE_EQ,
    NODE_LESS,
    NODE_MORE,
    NODE_LESSEQ,
    NODE_MOREEQ,
    NODE_AND,
    NODE_OR,
    NODE_NOT,
    NODE_BOOL,
    NODE_ASSIGNMENT,
    NODE_WHEN,
    NODE_LOOP,
    NODE_OUT,
    NODE_STATEMENT_LIST
} NodeType;

typedef struct ASTNode {
    NodeType type;
    union {
        int num;
        char* id;
    } value;
    struct ASTNode** children;
    int child_count;
} ASTNode;

ASTNode* create_node(NodeType type, int child_count, ...);
ASTNode* create_leaf(NodeType type, ...);
void free_ast(ASTNode* node);

#endif