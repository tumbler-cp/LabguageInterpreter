%{
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <cstdarg>
#include <string>
#include "ast_header.h"

void yyerror(const char *s);
int yylex();
extern char *yytext;
extern int yylineno;

ASTNode* program_root;
%}

%union {
    int num;
    char *id;
    ASTNode* node;
}

%token <num> NUMBER
%token <id> ID
%token LET WHEN THEN OTHER LOOP OUT NOT
%token AND OR EQ LESS MORE LESSEQ MOREEQ
%token MINUS PLUS MUL DIV MOD ASSIGN

%nonassoc NOT
%left AND OR
%left LESS MORE LESSEQ MOREEQ  
%left EQ
%left PLUS MINUS
%left MUL DIV MOD

%type <node> program
%type <node> statement_list
%type <node> statement
%type <node> when_else_opt
%type <node> condition
%type <node> expr

%%

program:
    statement_list { program_root = $1; }
    ;

statement_list:
    statement { $$ = create_node(NODE_STATEMENT_LIST, 1, $1); }
    | statement_list statement { $$ = create_node(NODE_STATEMENT_LIST, 2, $1, $2); }
    ;

statement:
    LET ID ASSIGN expr ';' { 
        $$ = create_node(NODE_ASSIGNMENT, 2, create_leaf(NODE_VAR, $2), $4); 
    }
    | ID ASSIGN expr ';' { 
        $$ = create_node(NODE_ASSIGNMENT, 2, create_leaf(NODE_VAR, $1), $3); 
    }
    | WHEN condition THEN statement when_else_opt { 
        $$ = create_node(NODE_WHEN, 3, $2, $4, $5); 
    }
    | LOOP condition statement {
        $$ = create_node(NODE_LOOP, 2, $2, $3);
    }
    | OUT expr ';' { $$ = create_node(NODE_OUT, 1, $2); }
    | '{' statement_list '}' { $$ = $2; }
    ;

when_else_opt:
    /* empty */ { $$ = nullptr; }
    | OTHER statement { $$ = $2; }
    ;

condition:
    expr EQ expr          { $$ = create_node(NODE_EQ, 2, $1, $3); }
    | expr LESS expr      { $$ = create_node(NODE_LESS, 2, $1, $3); }
    | expr MORE expr      { $$ = create_node(NODE_MORE, 2, $1, $3); }
    | expr LESSEQ expr    { $$ = create_node(NODE_LESSEQ, 2, $1, $3); }
    | expr MOREEQ expr    { $$ = create_node(NODE_MOREEQ, 2, $1, $3); }
    | condition AND condition { $$ = create_node(NODE_AND, 2, $1, $3); }
    | condition OR condition  { $$ = create_node(NODE_OR, 2, $1, $3); }
    | NOT condition       { $$ = create_node(NODE_NOT, 1, $2); }
    | '(' condition ')'   { $$ = $2; }
    | expr                { $$ = create_node(NODE_BOOL, 1, $1); }
    ;

expr:
    NUMBER                { $$ = create_leaf(NODE_NUM, $1); }
    | ID                  { $$ = create_leaf(NODE_VAR, $1); }
    | expr PLUS expr      { $$ = create_node(NODE_PLUS, 2, $1, $3); }
    | expr MINUS expr     { $$ = create_node(NODE_MINUS, 2, $1, $3); }
    | expr MUL expr       { $$ = create_node(NODE_MUL, 2, $1, $3); }
    | expr MOD expr       { $$ = create_node(NODE_MOD, 2, $1, $3); }
    | expr DIV expr       { $$ = create_node(NODE_DIV, 2, $1, $3); }
    | '(' expr ')'        { $$ = $2; }
    | MINUS expr          { $$ = create_node(NODE_UMINUS, 1, $2); }
    ;

%%

ASTNode* create_node(NodeType type, int child_count, ...) {
    ASTNode* node = new ASTNode();
    node->type = type;
    node->child_count = child_count;
    node->children = new ASTNode*[child_count];
    
    va_list args;
    va_start(args, child_count);
    for (int i = 0; i < child_count; i++) {
        node->children[i] = va_arg(args, ASTNode*);
    }
    va_end(args);
    
    return node;
}

ASTNode* create_leaf(NodeType type, ...) {
    ASTNode* node = new ASTNode();
    node->type = type;
    node->child_count = 0;
    node->children = nullptr;
    
    va_list args;
    va_start(args, type);
    if (type == NODE_NUM) {
        node->value.num = va_arg(args, int);
    } else if (type == NODE_VAR) {
        char* id = va_arg(args, char*);
        node->value.id = strdup(id);
    }
    va_end(args);
    
    return node;
}

void yyerror(const char *s) {
    std::cerr << "Error at line " << yylineno << ": " << s << " near '" << yytext << "'" << std::endl;
}