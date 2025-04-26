CC = g++
CFLAGS = -Wall -std=c++11
LEX = flex
YACC = bison

TARGET = compiler
SRCS = main.cpp
PARSER = parser.y
LEXER = lexer.l
AST_HEADER = ast_header.h

PARSER_C = parser.tab.c
PARSER_H = parser.tab.h
LEXER_C = lex.yy.c

all: $(TARGET)

$(TARGET): $(LEXER_C) $(PARSER_C) $(SRCS) $(AST_HEADER)
	$(CC) $(CFLAGS) -o $@ $(LEXER_C) $(PARSER_C) $(SRCS)

$(LEXER_C): $(LEXER)
	$(LEX) -o $@ $<

$(PARSER_C): $(PARSER)
	$(YACC) -d -o $@ $<

clean:
	rm -f $(TARGET) $(LEXER_C) $(PARSER_C) $(PARSER_H) *.o

.PHONY: all clean