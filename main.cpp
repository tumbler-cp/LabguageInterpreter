#include <iostream>
#include <fstream>
#include <string>
#include <unordered_map>
#include <memory>
#include <stdexcept>
#include "ast_header.h"

extern int yyparse(void);
extern FILE* yyin;

extern ASTNode* program_root;

class SymbolTable {
private:
    std::unordered_map<std::string, int> variables;

public:
    int& getVariable(const std::string& name) {
        return variables[name]; // автоматически создаст запись с 0, если не существует
    }

    void setVariable(const std::string& name, int value) {
        variables[name] = value;
    }

    bool exists(const std::string& name) const {
        return variables.find(name) != variables.end();
    }
};

SymbolTable symbol_table;

int evalExpr(ASTNode* node) {
    if (!node) return 0;
    
    switch (node->type) {
        case NODE_NUM: return node->value.num;
        case NODE_VAR: return symbol_table.getVariable(node->value.id);
        case NODE_PLUS: return evalExpr(node->children[0]) + evalExpr(node->children[1]);
        case NODE_MINUS: return evalExpr(node->children[0]) - evalExpr(node->children[1]);
        case NODE_MUL: return evalExpr(node->children[0]) * evalExpr(node->children[1]);
        case NODE_DIV: {
            int divisor = evalExpr(node->children[1]);
            if (divisor == 0) {
                throw std::runtime_error("Division by zero");
            }
            return evalExpr(node->children[0]) / divisor;
        }
        case NODE_MOD: return evalExpr(node->children[0]) % evalExpr(node->children[1]);
        case NODE_UMINUS: return -evalExpr(node->children[0]);
        default:
            throw std::runtime_error("Unknown expression type");
    }
}

bool evalCondition(ASTNode* node) {
    if (!node) return false;
    
    switch (node->type) {
        case NODE_EQ: return evalExpr(node->children[0]) == evalExpr(node->children[1]);
        case NODE_LESS: return evalExpr(node->children[0]) < evalExpr(node->children[1]);
        case NODE_MORE: return evalExpr(node->children[0]) > evalExpr(node->children[1]);
        case NODE_LESSEQ: return evalExpr(node->children[0]) <= evalExpr(node->children[1]);
        case NODE_MOREEQ: return evalExpr(node->children[0]) >= evalExpr(node->children[1]);
        case NODE_AND: return evalCondition(node->children[0]) && evalCondition(node->children[1]);
        case NODE_OR: return evalCondition(node->children[0]) || evalCondition(node->children[1]);
        case NODE_BOOL: return evalExpr(node->children[0]) != 0;
        case NODE_NOT: return !evalCondition(node->children[0]);
        default:
            throw std::runtime_error("Unknown condition type");
    }
}

void executeAst(ASTNode* node) {
    if (!node) return;
    
    try {
        switch (node->type) {
            case NODE_STATEMENT_LIST:
                for (int i = 0; i < node->child_count; i++) {
                    executeAst(node->children[i]);
                }
                break;
                
            case NODE_ASSIGNMENT: {
                int value = evalExpr(node->children[1]);
                symbol_table.setVariable(node->children[0]->value.id, value);
                break;
            }
                
            case NODE_WHEN: {
                bool condition = evalCondition(node->children[0]);
                if (condition) {
                    executeAst(node->children[1]);
                } else if (node->child_count > 2 && node->children[2]) {
                    executeAst(node->children[2]);
                }
                break;
            }
                
            case NODE_LOOP: {
                while (evalCondition(node->children[0])) {
                    executeAst(node->children[1]);
                }
                break;
            }
                
            case NODE_OUT: {
                int value = evalExpr(node->children[0]);
                std::cout << value << std::endl;
                break;
            }
                
            default:
                throw std::runtime_error("Unknown statement type");
        }
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
    }
}

void freeAst(ASTNode* node) {
    if (!node) return;
    
    for (int i = 0; i < node->child_count; i++) {
        freeAst(node->children[i]);
    }
    
    if (node->type == NODE_VAR) {
        delete[] node->value.id;
    }
    
    if (node->children) {
        delete[] node->children;
    }
    
    delete node;
}

int main(int argc, char** argv) {
    try {
        if (argc > 1) {
            yyin = fopen(argv[1], "r");
            if (!yyin) {
                std::cerr << "Could not open file " << argv[1] << std::endl;
                return 1;
            }
        } else {
            std::cerr << "Usage: " << argv[0] << " <filename>" << std::endl;
            return 1;
        }
        
        yyparse();
        
        if (program_root) {
            executeAst(program_root);
            freeAst(program_root);
        }
        
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Fatal error: " << e.what() << std::endl;
        return 1;
    }
}