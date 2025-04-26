%{
#include "ast_header.h"
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
%}

%option noyywrap
%option yylineno

DIGIT   [0-9]
LETTER  [a-zA-Z_]
ID      {LETTER}({LETTER}|{DIGIT})*

%%

"let"       { return LET; }
"when"      { return WHEN; }
"then"      { return THEN; }
"other"     { return OTHER; }
"loop"      { return LOOP; }
"out"       { return OUT; }
"and"       { return AND; }
"or"        { return OR; }
"is"        { return EQ; }
"not"       { return NOT; }
"<"         { return LESS; }
">"         { return MORE; }
"<="        { return LESSEQ; }
">="        { return MOREEQ; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MUL; }
"/"         { return DIV; }
"%"         { return MOD; }
"="         { return ASSIGN; }
";"         { return ';'; }
"{"         { return '{'; }
"}"         { return '}'; }
"("         { return '('; }
")"         { return ')'; }
{ID}        { yylval.id = strdup(yytext); return ID; }
{DIGIT}+    { yylval.num = atoi(yytext); return NUMBER; }
[ \t\n]     ; /* skip whitespace */
.           { yyerror("Invalid character"); }

%%