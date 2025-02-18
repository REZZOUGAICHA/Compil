// semantic.c
#include "semantic.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#define YYERROR return


// fonctions de gestion de liste
ArrayType* createArray() {
    ArrayType* arr = malloc(sizeof(ArrayType));
    if (!arr) return NULL;
    

    arr->length = 0;
    arr->capacity = 10;  // Initial capacity
    arr->data = malloc(arr->capacity * sizeof(char*));
    
    if (!arr->data) {
        free(arr);
        return NULL;
    }
    
    return arr;
}

ArrayType* createArrayFromExprList(ExpressionList* list) {
    if (!list) return NULL;
    
    // Count elements first
    size_t count = 0;
    ExpressionList* current = list;
    while (current) {
        count++;
        current = current->next;
    }
    
    // Create array with exact size needed
    ArrayType* arr = malloc(sizeof(ArrayType));
    if (!arr) return NULL;
    
    arr->length = count;
    arr->capacity = count;
    arr->data = malloc(count * sizeof(char*));
    
    if (!arr->data) {
        free(arr);
        return NULL;
    }
    
    // Copy values
    current = list;
    for (size_t i = 0; i < count && current; i++) {
        arr->data[i] = strdup(current->expr.value);
        if (!arr->data[i]) {
            // Cleanup on failure
            for (size_t j = 0; j < i; j++) {
                free(arr->data[j]);
            }
            free(arr->data);
            free(arr);
            return NULL;
        }
        current = current->next;
    }
    
    return arr;
}

ExpressionList* createExpressionNode(expression expr) {
    ExpressionList* node = malloc(sizeof(ExpressionList));
    if (node) {
        node->expr = expr;
        node->next = NULL;
    }
    return node;
}

ExpressionList* addExpressionToList(ExpressionList* list, expression expr) {
    if (!list) {
        return createExpressionNode(expr);
    }
    ExpressionList* current = list;
    while (current->next != NULL) {
        current = current->next;
    }
    current->next = createExpressionNode(expr);
    return list;
}



// conversion vers chaine de caractères de la valeur et type pour stockage dans table des symboles

void getTypeString(int type, char *typeStr) {
    switch(type) {
        case TYPE_INTEGER:
            strcpy(typeStr, "int");
            break;
        case TYPE_FLOAT:
            strcpy(typeStr, "float");
            break;
        case TYPE_BOOLEAN:
            strcpy(typeStr, "bool");
            break;
        case TYPE_STRING:
            strcpy(typeStr, "string");
            break;
        case TYPE_ARRAY:
            strcpy(typeStr, "array");
            break;
        case TYPE_DICT:     
            strcpy(typeStr, "dict");
            break;
        default:
            printf("Unsupported type returned by getTypeString %d\n", type);
            yyerror("Unsupported type returned by getTypeString");
            YYERROR;
    }
}
void createValueString(int type, const char *inputValue, char *valueStr) 
{
    if (inputValue == NULL || strlen(inputValue) == 0) {        
        switch(type) {
            case TYPE_INTEGER:
                snprintf(valueStr, MAX_VALUE_LENGTH, "%d", 0);
                break;
            case TYPE_FLOAT:
                snprintf(valueStr, MAX_VALUE_LENGTH, "%.2f", 0.0);
                break;
            case TYPE_BOOLEAN:
                strncpy(valueStr, "false", MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            case TYPE_STRING:
                strncpy(valueStr, "", MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            case TYPE_ARRAY:
                strncpy(valueStr, "[]", MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            case TYPE_DICT:     
                strncpy(valueStr, "{}", MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            default:
                yyerror("Unsupported type returned by createValueString 1");
                YYERROR;
        }
    } else {
        switch(type) {
            case TYPE_INTEGER:
                snprintf(valueStr, MAX_VALUE_LENGTH, "%d", atoi(inputValue));
                break;
            case TYPE_FLOAT:
                snprintf(valueStr, MAX_VALUE_LENGTH, "%.2f", atof(inputValue));
                break;
            case TYPE_BOOLEAN:
                strncpy(valueStr, inputValue, MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            case TYPE_STRING:
                strncpy(valueStr, inputValue, MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            case TYPE_ARRAY:
                strncpy(valueStr, inputValue, MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            case TYPE_DICT:     
                strncpy(valueStr, inputValue, MAX_VALUE_LENGTH - 1);
                valueStr[MAX_VALUE_LENGTH - 1] = '\0';
                break;
            default:
                yyerror("Unsupported type returned by createValueString 2");
                
                YYERROR;
        }
    }
}