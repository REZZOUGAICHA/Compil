%{ 
#include <stdio.h>
#include <stdbool.h>
#include "syntaxique.tab.h"

extern void yyerror(const char *s);
extern int positionCurseur;
#define avancerCurseur() positionCurseur += yyleng
void erreurLexical() {
    fprintf(stderr, "Erreur lexicale à la ligne %d, colonne %d: caractère invalide '%s'\n", 
            yylineno, positionCurseur, yytext);
}


%}
%option noyywrap 
%option yylineno
%% 
 
"int"           { avancerCurseur(); printf("Type: int\n"); return INT; } 
"float"         { avancerCurseur(); printf("Type: float\n"); return FLOAT; } 
"bool"          { avancerCurseur(); printf("Type: bool\n"); return BOOL; } 
"str"           { avancerCurseur(); printf("Type: str\n"); return STR; } 
"const"         { avancerCurseur(); printf("Mot-clé: const\n"); return CONST; } 
"Array"         { avancerCurseur(); printf("Mot-clé: Array\n"); return ARRAY; } 
"Dict"          { avancerCurseur(); printf("Mot-clé: Dict\n"); return DICT; } 
"Function"      { avancerCurseur(); printf("Mot-clé: Function\n"); return FUNCTION; } 
"Let"           { avancerCurseur(); printf("Mot-clé: Let\n"); return LET; } 
"be"            { avancerCurseur(); printf("Mot-clé: be\n"); return BE; } 
"Call"          { avancerCurseur(); printf("Mot-clé: Call\n"); return CALL; } 
"with"          { avancerCurseur(); printf("Mot-clé: with\n"); return WITH; } 
"parameters"    { avancerCurseur(); printf("Mot-clé: parameters\n"); return PARAMETERS; } 
"if"            { avancerCurseur(); printf("Mot-clé: If\n"); return IF; }
"else"          { avancerCurseur(); printf("Mot-clé: Else\n"); return ELSE; }
"elseIf"        { avancerCurseur(); printf("Mot-clé: ElseIf\n"); return ELSEIF; }
"EndIf"         { avancerCurseur(); printf("Mot-clé: EndIf\n"); return ENDIF; }
"For"           { avancerCurseur(); printf("Mot-clé: For\n"); return FOR; } 
"each"          { avancerCurseur(); printf("Mot-clé: each\n"); return EACH; } 
"in"            { avancerCurseur(); printf("Mot-clé: in\n"); return IN; } 
"EndFor"        { avancerCurseur(); printf("Mot-clé: EndFor\n"); return ENDFOR; } 
"While"         { avancerCurseur(); printf("Mot-clé: While\n"); return WHILE; } 
"EndWhile"      { avancerCurseur(); printf("Mot-clé: EndWhile\n"); return ENDWHILE; } 
"Repeat"        { avancerCurseur(); printf("Mot-clé: Repeat\n"); return REPEAT; } 
"Until"         { avancerCurseur(); printf("Mot-clé: Until\n"); return UNTIL; } 
"EndRepeat"     { avancerCurseur(); printf("Mot-clé: EndRepeat\n"); return ENDREPEAT; } 
"Input"         { avancerCurseur(); printf("Mot-clé: Input\n"); return INPUT; } 
"to"            { avancerCurseur(); printf("Mot-clé: to\n"); return TO; } 
"Print"         { avancerCurseur(); printf("Mot-clé: Print\n"); return PRINT; } 
"Switch"        { avancerCurseur(); printf("Mot-clé: Switch\n"); return SWITCH; } 
"Case"          { avancerCurseur(); printf("Mot-clé: Case\n"); return CASE; } 
"Default"       { avancerCurseur(); printf("Mot-clé: Default\n"); return DEFAULT; } 
"EndSwitch"     { avancerCurseur(); printf("Mot-clé: EndSwitch\n"); return ENDSWITCH; } 
"return"        { avancerCurseur(); printf("Mot-clé: Return\n"); return RETURN; } 
"+"             { avancerCurseur(); printf("Opérateur arithmétique: Addition\n"); return ADD; } 
"-"             { avancerCurseur(); printf("Opérateur arithmétique: Soustraction\n"); return SUB; } 
"*"             { avancerCurseur(); printf("Opérateur arithmétique: Multiplication\n"); return MUL; } 
"/"             { avancerCurseur(); printf("Opérateur arithmétique: Division\n"); return DIV; } 
"//"            { avancerCurseur(); printf("Opérateur arithmétique: Division entière\n"); return INT_DIV; } 
"%"             { avancerCurseur(); printf("Opérateur arithmétique: Modulo\n"); return MOD; } 
"=="            { avancerCurseur(); printf("Opérateur de comparaison : Égal à\n"); return EQUAL; } 
"!="            { avancerCurseur(); printf("Opérateur de comparaison : Différent de\n"); return NOT_EQUAL; } 
">"             { avancerCurseur(); printf("Opérateur de comparaison : Plus grand que\n"); return GREATER_THAN; } 
"<"             { avancerCurseur(); printf("Opérateur de comparaison : Plus petit que\n"); return LESS_THAN; } 
">="            { avancerCurseur(); printf("Opérateur de comparaison : Plus grand ou égal à\n"); return GREATER_EQUAL; } 
"<="            { avancerCurseur(); printf("Opérateur de comparaison : Plus petit ou égal à\n"); return LESS_EQUAL; } 
 
":"             { avancerCurseur(); printf("Deux-points\n"); return COLON; } 
"("             { avancerCurseur(); printf("Parenthèse ouvrante\n"); return LPAREN; } 
")"             { avancerCurseur(); printf("Parenthèse fermante\n"); return RPAREN; } 
"{"             { avancerCurseur(); printf("Accolade ouvrante\n"); return LBRACE; } 
"}"             { avancerCurseur(); printf("Accolade fermante\n"); return RBRACE; } 
","             { avancerCurseur(); printf("Virgule\n"); return COMMA; } 
"["             { avancerCurseur(); printf("Crochet ouvrant\n"); return LBRACKET; } 
"]"             { avancerCurseur(); printf("Crochet fermant\n"); return RBRACKET; } 
 
"and"           { avancerCurseur(); printf("Opérateur logique : ET logique\n"); return LOGICAL_AND; } 
"or"            { avancerCurseur(); printf("Opérateur logique : OU logique\n"); return LOGICAL_OR; } 
"not"           { avancerCurseur(); printf("Opérateur logique : Négation logique\n"); return LOGICAL_NOT; } 
 
"true"          { avancerCurseur(); printf("Booléen: true\n"); return TRUE; } 
"false"         { avancerCurseur(); printf("Booléen: false\n"); return FALSE; } 
"comment :"[^\n]*"." {avancerCurseur();  printf("Commentaire: %s\n", yytext); return COMMENT; } 
 
[0-9]+ { 
    avancerCurseur();
    yylval.integerValue = atoi(yytext);
    printf("Lexer recognized integer: %d\n", yylval.integerValue);
    return INT_LITERAL; 
} 
 
[0-9]+\.[0-9]+ { 
    avancerCurseur();
    yylval.floatValue = atof(yytext);  // Convert string to float
    printf("Nombre réel: %f\n", yylval.floatValue); 
    return FLOAT_LITERAL; 
}
 
\"([^\"\\]|\\.)*\" { 
    avancerCurseur();
    printf("Chaîne de caractères: %s\n", yytext);
    // Remove quotes and copy the string value
    strncpy(yylval.stringValue, yytext + 1, sizeof(yylval.stringValue) - 1);
    yylval.stringValue[strlen(yylval.stringValue) - 1] = '\0';  // Remove trailing quote
    return STRING_LITERAL; 
}
 
[ \t]+ {
    for (int i = 0; i < yyleng; i++) {
        if (yytext[i] == '\t') {
            positionCurseur += 4 - (positionCurseur % 4); // Assume a tab width of 4 spaces
        } else {
            positionCurseur++;
        }
    }
}

\n|\r|\r\n {
    positionCurseur = 0;
}

[a-zA-Z_][a-zA-Z0-9_]* {
    positionCurseur += yyleng;
    strncpy(yylval.identifier, yytext, 254);
    yylval.identifier[254] = '\0';
    printf("Identifier found: %s\n", yylval.identifier);
    return ID;
}

. {
    positionCurseur += yyleng; 
    erreurLexical();
}
%%