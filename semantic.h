// semantic.h
#ifndef SEMANTIC_H
#define SEMANTIC_H
#include <stdbool.h>
#include "tableSymboles.h"

typedef struct expression {
    int type;
    char value[MAX_NAME_LENGTH];  
    void* data;
} expression;


typedef struct ExpressionNode {
    expression expr;
    struct ExpressionNode* next;
} ExpressionList;


typedef struct variable {
    struct SymbolEntry* entry;
} variable;

// Function declarations
// Crée un tableau dynamique.
ArrayType* createArray();
// Crée un tableau à partir d'une liste d'expressions.
ArrayType* createArrayFromExprList(ExpressionList* list);
// Convertit un type numérique en une chaîne de caractères représentant le type.
void getTypeString(int type, char *typeStr);
// Convertit une valeur d'un type donné en une chaîne de caractères pour le stockage dans la table des symboles.
void createValueString(int type, const char *inputValue, char *valueStr);
// Crée un nœud pour une liste d'expressions à partir d'une expression donnée.
ExpressionList* createExpressionNode(expression expr);
// Ajoute une expression à la fin d'une liste d'expressions.
ExpressionList* addExpressionToList(ExpressionList* list, expression expr);

#endif // SEMANTIC_H