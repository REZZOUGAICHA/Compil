%define parse.error verbose

%{
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#define YYDEBUG 1
extern int yylex();
extern int yylineno; 
extern char* yytext;
extern FILE* yyin;
int positionCurseur = 0;
char *file = "input.txt";
void yyerror(const char *s);  
%}

%code requires{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include "semantic.h"
#include "tableSymboles.h"
#include "quadruplets.h"
#include "pile.h"


}


%union {
    char identifier[255];      
    int type;
    int integerValue;
    double floatValue;
    bool booleanValue;
    char stringValue[255];
    struct SymbolEntry* entry;
    expression expression;
    ExpressionList* exprList;
    variable variable;
}

%token <type> INT FLOAT BOOL STR 
%token CONST ARRAY DICT FUNCTION 
%token LET BE CALL WITH PARAMETERS
%token ELSEIF IF ELSE ENDIF
%token FOR EACH IN ENDFOR
%token WHILE ENDWHILE
%token REPEAT UNTIL ENDREPEAT
%token INPUT TO
%token PRINT
%token SWITCH CASE DEFAULT ENDSWITCH
%token RETURN

%token ADD SUB MUL DIV INT_DIV MOD
%token EQUAL NOT_EQUAL GREATER_THAN LESS_THAN GREATER_EQUAL LESS_EQUAL
%token COLON LPAREN RPAREN LBRACE RBRACE COMMA LBRACKET RBRACKET
%token LOGICAL_AND LOGICAL_OR LOGICAL_NOT 

%token <booleanValue> TRUE FALSE
%token <integerValue> INT_LITERAL 
%token <floatValue> FLOAT_LITERAL 
%token <stringValue> STRING_LITERAL
%token <identifier> ID    

%token COMMENT

/* Type definitions for non-terminals */
%type <expression> Expression SimpleExpression
%type <exprList> ExpressionList
%type <expression> ArrayLiteral
%type <type> Type
%type <entry> Declaration Parameter ParameterList NonEmptyParameterList
%type <variable> Assignment


%left LOGICAL_OR
%left LOGICAL_AND
%left EQUAL NOT_EQUAL
%left LESS_THAN GREATER_THAN LESS_EQUAL GREATER_EQUAL
%left ADD SUB
%left MUL DIV MOD INT_DIV
%right LOGICAL_NOT
%nonassoc UMINUS

%start Program
%{
extern FILE *yyin;
extern int yylineno;
extern int yyleng;
extern int yylex();
int currentColumn = 1;
SymbolTable *symbolTable;
pile * stack;
quad *q = NULL;  // quadruplet
int qc = 1; // pile

void yysuccess(char *s);
void yyerror(const char *s);
void showLexicalError();
%}
%%

Program:
    StatementList
    ;


StatementList:                   
    | StatementList Statement      
    ;


Statement:
    SimpleStatement
    | CompoundStatement
    | COMMENT
    | DictLiteral
    ;


SimpleStatement:
    Declaration
    | PrintStatement
    | Assignment
    | FunctionCall
    | InputStatement
    | RETURN Expression
    ;


CompoundStatement:
    LoopStatement
    | Function
    | Condition
    | SwitchStatement
    ;


LoopStatement:
    ForLoop
    | WhileLoop
    | RepeatLoop
    ;



ForLoop:
    FOR EACH ID IN Expression COLON StatementList ENDFOR
    ;


WhileLoop:
    WhileStart StatementList ENDWHILE {
        // Récupérer l'étiquette de départ depuis la pile
        int whileId = depiler(stack);
        
        // Générer les étiquettes
        char whileConditionLabel[20];
        char whileEndLabel[20];
        sprintf(whileConditionLabel, "WHILE_COND_%d", whileId);
        sprintf(whileEndLabel, "WHILE_END_%d", whileId);
        
        // Générer un saut inconditionnel vers la condition
        insererQuadreplet(&q, "BR", "", "", whileConditionLabel, qc++);
        // Placer l'étiquette de fin pour la boucle while
        insererQuadreplet(&q, whileEndLabel, "", "", "", qc++);
    }
    ;

WhileStart:
    WHILE Expression COLON {
        // Valider le type de l'expression
        if ($2.type != TYPE_BOOLEAN) {
            yyerror("While condition must be a boolean expression");
            YYERROR;
        }
        
        // Générer un ID unique pour cette boucle while
        int whileId = qc;
        
        // Générer les noms des étiquettes
        char whileConditionLabel[20];
        char whileEndLabel[20];
        sprintf(whileConditionLabel, "WHILE_COND_%d", whileId);
        sprintf(whileEndLabel, "WHILE_END_%d", whileId);
        insererQuadreplet(&q, whileConditionLabel, "", "", "", qc++);
        insererQuadreplet(&q, "BZ",whileEndLabel , "",   $2.value, qc++);
        empiler(stack, whileId);
    }
    ;


RepeatLoop: RepeatStart StatementList RepeatEnd;
RepeatStart: REPEAT COLON {
    int repeatId = qc;
    char repeatStartLabel[20];
    sprintf(repeatStartLabel, "REPEAT_START_%d", repeatId);
    insererQuadreplet(&q, repeatStartLabel, "", "", "", qc++);
    empiler(stack, repeatId);
}
RepeatEnd : UNTIL Expression ENDREPEAT
{
int repeatId = depiler(stack);
    char repeatStartLabel[20];
    char repeatEndLabel[20];
    sprintf(repeatStartLabel, "REPEAT_START_%d", repeatId);
    sprintf(repeatEndLabel, "REPEAT_END_%d", repeatId);
    char typeStr[MAX_TYPE_LENGTH];
        getTypeString($2.type, typeStr);

    if (!strcmp(typeStr,"boolean")) {
        yyerror("Repeat-until condition must be a boolean expression");
        YYERROR;
    }
    insererQuadreplet(&q, "BZ", repeatStartLabel, "",  $2.value, qc++);
    insererQuadreplet(&q, repeatEndLabel, "", "", "", qc++);
} 
;


Expression:
    SimpleExpression {
        $$ = $1;
    }
    | Expression ADD Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Valider les opérandes pour des valeurs nulles
    if (!$1.value || !$3.value) {
        yyerror("Operands for addition must be initialized and have valid values.");
        YYERROR;
    }

    // Obtenir les informations de type pour les opérandes
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // Gérer la concaténation de chaînes si les deux opérandes sont des chaînes
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        snprintf(resultValue, sizeof(resultValue), "%s%s", $1.value, $3.value);
        
        char valueStr[MAX_VALUE_LENGTH];


        $$.type = TYPE_STRING;
        strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';

        // Generate quadruplet for concatenation operation
        insererQuadreplet(&q, "CONCAT", $1.value, $3.value, temp, qc++);
    } 
    // Gérer l'addition numérique
    else {
        // addition
        if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
            $$.type = TYPE_FLOAT;
            float val1 = atof($1.value);
            float val2 = atof($3.value);
            snprintf(resultValue, sizeof(resultValue), "%.2f", val1 + val2);
            char valueStr[MAX_VALUE_LENGTH];

            strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
            $$.value[MAX_NAME_LENGTH - 1] = '\0';
            // Gérer l'addition de nombres à virgule flottante
            insererQuadreplet(&q, "+", $1.value, $3.value, temp, qc++);
        } 
        // Gérer l'addition de nombres entiers
        else {
            $$.type = TYPE_INTEGER;
            int val1 = atoi($1.value);
            int val2 = atoi($3.value);
            snprintf(resultValue, sizeof(resultValue), "%d", val1 + val2);

            char valueStr[MAX_VALUE_LENGTH];

            
            strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
            $$.value[MAX_NAME_LENGTH - 1] = '\0';
            // Générer un quadruplet pour l'opération d'addition
            insererQuadreplet(&q, "+", $1.value, $3.value, temp, qc++);
        }
    }
}

    | Expression SUB Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);
    
    if (!$1.value || !$3.value) {
        yyerror("Operands for subtraction must be initialized and have valid values.");
        YYERROR;
    }

    
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    
    if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        $$.type = TYPE_FLOAT;
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        snprintf(resultValue, sizeof(resultValue), "%.2f", val1 - val2);
        
        char valueStr[MAX_VALUE_LENGTH];        
       
        strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';

        
        insererQuadreplet(&q, "-", $1.value, $3.value, temp, qc++);
    } 
    
    else {
        $$.type = TYPE_INTEGER;
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        snprintf(resultValue, sizeof(resultValue), "%d", val1 - val2);
        
        char valueStr[MAX_VALUE_LENGTH];
        
        
        strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';

        
        insererQuadreplet(&q, "-", $1.value, $3.value, temp, qc++);
    }
}


    | Expression MUL Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    
    if (!$1.value || !$3.value) {
        yyerror("Operands for subtraction must be initialized and have valid values.");
        YYERROR;
    }

    //avoir type
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    //  float
    if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        $$.type = TYPE_FLOAT;
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        snprintf(resultValue, sizeof(resultValue), "%.2f", val1 * val2);
        
        char valueStr[MAX_VALUE_LENGTH];
        
        // sauvegarder le resultat dans expression
        strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';
        
        // Generer quadruplet 
        insererQuadreplet(&q, "-", $1.value, $3.value, temp, qc++);
    } 
    
    else {
        $$.type = TYPE_INTEGER;
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        snprintf(resultValue, sizeof(resultValue), "%d", val1 * val2);
        
        char valueStr[MAX_VALUE_LENGTH];
        
        
        strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';

        
        insererQuadreplet(&q, "-", $1.value, $3.value, temp, qc++);
    }
}

    | Expression DIV Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    
    if (!$1.value || !$3.value) {
        yyerror("Operands for division must be initialized and have valid values.");
        YYERROR;
    }

    // division par zero 
    if (atof($3.value) == 0) {
        yyerror("Division by zero error");
        YYERROR;
    }

    
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // retourner float pour division réguliere 
    $$.type = TYPE_FLOAT;
    float val1 = atof($1.value);
    float val2 = atof($3.value);
    snprintf(resultValue, sizeof(resultValue), "%.2f", val1 / val2);
    
    char valueStr[MAX_VALUE_LENGTH];
    
    
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    
    insererQuadreplet(&q, "/", $1.value, $3.value, temp, qc++);
}




    | Expression INT_DIV Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Valider operands
    if (!$1.value || !$3.value) {
        yyerror("Operands for integer division must be initialized and have valid values.");
        YYERROR;
    }

    // division par zero
    if (atoi($3.value) == 0) {
        yyerror("Division by zero error");
        YYERROR;
    }

    // type
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    
    $$.type = TYPE_INTEGER;
    int val1 = atoi($1.value);
    int val2 = atoi($3.value);
    snprintf(resultValue, sizeof(resultValue), "%d", val1 / val2);

    char valueStr[MAX_VALUE_LENGTH];
    
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    insererQuadreplet(&q, "DIV", $1.value, $3.value, temp, qc++);
}

    | Expression MOD Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    
    if (!$1.value || !$3.value) {
        yyerror("Operands for modulo must be initialized and have valid values.");
        YYERROR;
    }

    
    if (atoi($3.value) == 0) {
        yyerror("Modulo by zero error");
        YYERROR;
    }

    
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    
    $$.type = TYPE_INTEGER;
    int val1 = atoi($1.value);
    int val2 = atoi($3.value);
    snprintf(resultValue, sizeof(resultValue), "%d", val1 % val2);
    
    char valueStr[MAX_VALUE_LENGTH];
    
    
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    
    insererQuadreplet(&q, "MOD", $1.value, $3.value, temp, qc++);
}


    |Expression EQUAL Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    
    if (!$1.value || !$3.value) {
        yyerror("Operands for equality comparison must be initialized and have valid values.");
        YYERROR;
    }

   
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // comparaison des string 
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        int result = strcmp($1.value, $3.value) == 0;
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }
    // comparaison numerique
    else {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        int result = (val1 == val2);
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }

    // type
    $$.type = TYPE_BOOLEAN;
    
    char valueStr[MAX_VALUE_LENGTH];
    
    
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    
    insererQuadreplet(&q, "==", $1.value, $3.value, temp, qc++);
}


    | Expression NOT_EQUAL Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    
    if (!$1.value || !$3.value) {
        yyerror("Operands for inequality comparison must be initialized and have valid values.");
        YYERROR;
    }

    
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        int result = strcmp($1.value, $3.value) != 0;
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }
    //numerique
    else {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        int result = (val1 != val2);
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }

    // mettre le type boolean
    $$.type = TYPE_BOOLEAN;
    
    char valueStr[MAX_VALUE_LENGTH];
    
   
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    
    insererQuadreplet(&q, "!=", $1.value, $3.value, temp, qc++);
}


    |Expression GREATER_THAN Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    // Valider operands
    if (!$1.value || !$3.value) {
        yyerror("Operands for greater than comparison must be initialized and have valid values.");
        YYERROR;
    }

    
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        int result = strcmp($1.value, $3.value) > 0;
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }
    
    else if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        int result = (val1 > val2);
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }
    
    else {
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        int result = (val1 > val2);
        snprintf(resultValue, sizeof(resultValue), "%s", result ? "true" : "false");
    }

    
    $$.type = TYPE_BOOLEAN;
    
    char valueStr[MAX_VALUE_LENGTH];
    
    
    strncpy($$.value, resultValue, MAX_NAME_LENGTH - 1);
    $$.value[MAX_NAME_LENGTH - 1] = '\0';

    
    insererQuadreplet(&q, ">", $1.value, $3.value, temp, qc++);
}



    | Expression LESS_THAN Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    
    if (!$1.value || !$3.value) {
        yyerror("Operands for less than comparison must be initialized and have valid values.");
        YYERROR;
    }

    
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        strcpy(resultValue, strcmp($1.value, $3.value) < 0 ? "true" : "false");
    }
    
    else if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        strcpy(resultValue, val1 < val2 ? "true" : "false");
    }
    
    else {
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        strcpy(resultValue, val1 < val2 ? "true" : "false");
    }

    
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

    
    insererQuadreplet(&q, "<", $1.value, $3.value, temp, qc++);
}


    | Expression GREATER_EQUAL Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    
    if (!$1.value || !$3.value) {
        yyerror("Operands for greater than or equal comparison must be initialized and have valid values.");
        YYERROR;
    }

    
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        strcpy(resultValue, strcmp($1.value, $3.value) >= 0 ? "true" : "false");
    }
    
    else if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        strcpy(resultValue, val1 >= val2 ? "true" : "false");
    }
    
    else {
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        strcpy(resultValue, val1 >= val2 ? "true" : "false");
    }

    
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

    
    insererQuadreplet(&q, ">=", $1.value, $3.value, temp, qc++);
}


    | Expression LESS_EQUAL Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    
    if (!$1.value || !$3.value) {
        yyerror("Operands for less than or equal comparison must be initialized and have valid values.");
        YYERROR;
    }

    
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    
    if (strcmp(type1Str, "string") == 0 && strcmp(type3Str, "string") == 0) {
        strcpy(resultValue, strcmp($1.value, $3.value) <= 0 ? "true" : "false");
    }
    
    else if (strcmp(type1Str, "float") == 0 || strcmp(type3Str, "float") == 0) {
        float val1 = atof($1.value);
        float val2 = atof($3.value);
        strcpy(resultValue, val1 <= val2 ? "true" : "false");
    }
    
    else {
        int val1 = atoi($1.value);
        int val2 = atoi($3.value);
        strcpy(resultValue, val1 <= val2 ? "true" : "false");
    }

    
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

    
    insererQuadreplet(&q, "<=", $1.value, $3.value, temp, qc++);
}


    | Expression LOGICAL_AND Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);
    if (!$1.value || !$3.value) {
        yyerror("Operands for logical AND must be initialized and have valid values.");
        YYERROR;
    }

   
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    // les deux operandes doivent etre boolean
    if ($1.type != TYPE_BOOLEAN || $3.type != TYPE_BOOLEAN) {
        yyerror("Logical AND requires boolean operands");
        YYERROR;
    }

    //and
    bool val1 = strcmp($1.value, "true") == 0;
    bool val2 = strcmp($3.value, "true") == 0;
    strcpy(resultValue, (val1 && val2) ? "true" : "false");

   
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

    
    insererQuadreplet(&q, "AND", $1.value, $3.value, temp, qc++);
}
 

    | Expression LOGICAL_OR Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

    
    if (!$1.value || !$3.value) {
        yyerror("Operands for logical OR must be initialized and have valid values.");
        YYERROR;
    }

   
    char type1Str[MAX_TYPE_LENGTH];
    char type3Str[MAX_TYPE_LENGTH];
    getTypeString($1.type, type1Str);
    getTypeString($3.type, type3Str);

    
    if ($1.type != TYPE_BOOLEAN || $3.type != TYPE_BOOLEAN) {
        yyerror("Logical OR requires boolean operands");
        YYERROR;
    }

    //or
    bool val1 = strcmp($1.value, "true") == 0;
    bool val2 = strcmp($3.value, "true") == 0;
    strcpy(resultValue, (val1 || val2) ? "true" : "false");

   
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

  
    insererQuadreplet(&q, "OR", $1.value, $3.value, temp, qc++);
}


    | LOGICAL_NOT Expression {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

   
    if (!$2.value) {
        yyerror("Operand for logical NOT must be initialized and have a valid value.");
        YYERROR;
    }

    
    char typeStr[MAX_TYPE_LENGTH];
    getTypeString($2.type, typeStr);

   
    if ($2.type != TYPE_BOOLEAN) {
        yyerror("Logical NOT requires a boolean operand");
        YYERROR;
    }


    bool val = strcmp($2.value, "true") == 0;
    strcpy(resultValue, (!val) ? "true" : "false");

  
    $$.type = TYPE_BOOLEAN;
    strcpy($$.value, resultValue);

   
    insererQuadreplet(&q, "NOT", $2.value, "", temp, qc++);
}


    | SUB Expression %prec UMINUS {
    char resultValue[MAX_VALUE_LENGTH];
    char temp[MAX_NAME_LENGTH];
    snprintf(temp, sizeof(temp), "t%d", qc);

 
    if (!$2.value) {
        yyerror("Operand for unary minus must be initialized and have a valid value.");
        YYERROR;
    }

  
    char typeStr[MAX_TYPE_LENGTH];
    getTypeString($2.type, typeStr);

    //float negation
    if (strcmp(typeStr, "float") == 0) {
        $$.type = TYPE_FLOAT;
        float val = -atof($2.value);
        snprintf(resultValue, sizeof(resultValue), "%.2f", val);
    }
    //  integer negation
    else if (strcmp(typeStr, "int") == 0) {
        $$.type = TYPE_INTEGER;
        int val = -atoi($2.value);
        snprintf(resultValue, sizeof(resultValue), "%d", val);
    }
    // non-numeric types
    else {
        yyerror("Unary minus requires numeric operand");
        YYERROR;
    }

    strcpy($$.value, resultValue);

    
    insererQuadreplet(&q, "UMINUS", $2.value, "", temp, qc++);
}
    ;





SimpleExpression:
    INT_LITERAL {
        $$.type = TYPE_INTEGER;
        snprintf($$.value, MAX_NAME_LENGTH, "%d", $1);
    }
    | FLOAT_LITERAL {
        $$.type = TYPE_FLOAT;
        snprintf($$.value, MAX_NAME_LENGTH, "%.2f", $1);
    }
    | STRING_LITERAL {
        $$.type = TYPE_STRING;
        strncpy($$.value, $1, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';
    }
    | TRUE {
        $$.type = TYPE_BOOLEAN;
        strcpy($$.value, "true");
    }
    | FALSE {
        $$.type = TYPE_BOOLEAN;
        strcpy($$.value, "false");
    }
    | 
    ID {
        SymbolEntry *symbol = lookupSymbolByName(symbolTable, $1, 0);
        if (!symbol) {
            yyerror("Undefined identifier");
            YYERROR;
        }
        if (strcmp(symbol->type, "int") == 0) $$.type = TYPE_INTEGER;
        else if (strcmp(symbol->type, "float") == 0) $$.type = TYPE_FLOAT;
        else if (strcmp(symbol->type, "string") == 0) $$.type = TYPE_STRING;
        else if (strcmp(symbol->type, "bool") == 0) $$.type = TYPE_BOOLEAN;
        
        strncpy($$.value, symbol->value, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';
    }
    | ArrayLiteral {
        $$ = $1;
    }
    ;
Declaration:
    LET Type ID BE Expression {

        if (symbolExistsByName(symbolTable, $3, 0)) {
            char error[100];
            snprintf(error, sizeof(error), "Symbol '%s' already declared", $3);
            yyerror(error);
            YYERROR;
        }
        char exprTypeStr[MAX_TYPE_LENGTH];
        getTypeString($5.type, exprTypeStr);
        printf("Expression type: %s\n", exprTypeStr);

        // Validate types match
        char typeStr[MAX_TYPE_LENGTH];
        getTypeString($2, typeStr);
        printf("Type retourne: %s\n", typeStr);

         if ($2 != $5.type) {
            char error[100];
            snprintf(error, sizeof(error), 
                    "Type mismatch: Cannot assign %s to variable of type %s", 
                    exprTypeStr, typeStr);
            yyerror(error);
            YYERROR;
        }

        // string 
        char valueStr[MAX_VALUE_LENGTH];
        insertSymbol(symbolTable, $3, typeStr, valueStr, 0, false, true);
        
       
        char temp[20];
        insererQuadreplet(&q, ":=", valueStr, "", $3, qc++);

        
        $$ = lookupSymbolByName(symbolTable, $3, 0);
        if (!$$) {
            yyerror("Failed to retrieve newly inserted symbol");
            YYERROR;
        }
        
        
    }
    | CONST Type ID BE Expression {
        if (symbolExistsByName(symbolTable, $3, 0)) {
            char error[100];
            snprintf(error, sizeof(error), "Symbol '%s' already declared", $3);
            yyerror(error);
            YYERROR;
        }

                // valider correspndace type 
        char typeStr[MAX_TYPE_LENGTH];
        getTypeString($2, typeStr);
                char exprTypeStr[MAX_TYPE_LENGTH];
        getTypeString($5.type, exprTypeStr);
        printf("Expression type: %s\n", exprTypeStr);
            if ($2 != $5.type) {
        char error[100];
        snprintf(error, sizeof(error), 
                "Type mismatch: Cannot assign %s to constant of type %s", 
                exprTypeStr, typeStr);
        yyerror(error);
        YYERROR;
    }

       
        char valueStr[MAX_VALUE_LENGTH];
        insertSymbol(symbolTable, $3, typeStr, $5.value, 0, true, true);
        
       
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, ":=", valueStr, "", $3, qc++);
        $$ = lookupSymbolByName(symbolTable, $3, 0);
        if (!$$) {
            yyerror("Failed to retrieve newly inserted symbol");
            YYERROR;
        }
    }
    | Type ID {
     
        if (symbolExistsByName(symbolTable, $2, 0)) {
            char error[100];
            snprintf(error, sizeof(error), "Symbol '%s' already declared", $2);
            yyerror(error);
            YYERROR;
        }
        char typeStr[MAX_TYPE_LENGTH];
        char valueStr[MAX_VALUE_LENGTH];
        getTypeString($1, typeStr);
        insertSymbol(symbolTable, $2, typeStr, NULL, 0, false, false);
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, ":=", valueStr, "", $2, qc++);
        $$ = lookupSymbolByName(symbolTable, $2, 0);
        if (!$$) {
            yyerror("Failed to retrieve newly inserted symbol");
            YYERROR;
        }

    }
    ;
    |   LET ARRAY ID BE ArrayLiteral {
        printf("Array declaration with initialization started\n");
       
        if (symbolExistsByName(symbolTable, $3, 0)) {
            yyerror("Cannot redeclare identifier");
            YYERROR;
        }
        
     
        char typeStr[MAX_TYPE_LENGTH];
        getTypeString(TYPE_ARRAY, typeStr);
        
        
        // creer  array entry dans table des symboles
        insertSymbol(symbolTable, $3, typeStr, "[]", 0, false, true);
        
        // dernier symbol crée
        SymbolEntry* arraySymbol = lookupSymbolByName(symbolTable, $3, 0);
        if (!arraySymbol) {
            yyerror("Failed to create array symbol");
            YYERROR;
        }
        
        //type correspondance
        expression arrayExpr = $5;
        if (arrayExpr.type != TYPE_ARRAY) {
            yyerror("Type mismatch: Expected array literal");
            YYERROR;
        }
        
        // maj valeur
        updateSymbolValue(symbolTable, arraySymbol->id, arrayExpr.value, 0);
        
        //  quadruplet
        char temp[20];
        sprintf(temp, "t%d", qc);
        insererQuadreplet(&q, "ARRAY_DECL", $3, arrayExpr.value, temp, qc++);
        
        $$ = arraySymbol;
        printf("Array '%s' declared successfully\n", $3);
    }
    ;

Type:
    INT     { 
        $$ = TYPE_INTEGER;  
    }
    | FLOAT { 
        $$ = TYPE_FLOAT;
        
    }
    | BOOL  { 
        $$ = TYPE_BOOLEAN;
        
    }
    | STR   { 
        $$ = TYPE_STRING;
        
    }
    | ARRAY { 
        $$ = TYPE_ARRAY;
    }
    ;


Assignment:
    LET ID BE Expression {
        // id existe ?
        SymbolEntry *symbol = lookupSymbolByName(symbolTable, $2, 0);
        if (!symbol) {
            yyerror("Undefined identifier");
            YYERROR;
        }
        
        if (symbol->isConst) {
            yyerror("Cannot modify constant value");
            YYERROR;
        }
        
        // compatibilité des types
        int symbolType;
        if (strcmp(symbol->type, "int") == 0) symbolType = TYPE_INTEGER;
        else if (strcmp(symbol->type, "float") == 0) symbolType = TYPE_FLOAT;
        else if (strcmp(symbol->type, "string") == 0) symbolType = TYPE_STRING;
        else if (strcmp(symbol->type, "bool") == 0) symbolType = TYPE_BOOLEAN;
        
        if (symbolType != $4.type) {
            yyerror("Type mismatch in assignment");
            YYERROR;
        }
        
        //maj symbol
        updateSymbolValue(symbolTable, symbol->id, $4.value, 0);
        
        // quadruplet 
        insererQuadreplet(&q, ":=", $4.value, "", $2, qc++);
    }
PrintStatement:
    PRINT Expression 
    ;

InputStatement:
    INPUT Expression TO ID 
    ;



Function:
    FUNCTION ID COLON Type LPAREN ParameterList RPAREN LBRACE StatementList RBRACE
    ;



FunctionCall:
    CALL ID WITH PARAMETERS ParameterList LPAREN ExpressionList RPAREN {
        printf("Appel valide avec parametres\n");
    }
    | CALL ID LPAREN RPAREN {
        printf("Appel valide sans parametres\n");
    }
    ;


ParameterList:
    
    | NonEmptyParameterList
    ;

NonEmptyParameterList:
    Parameter
    | NonEmptyParameterList COMMA Parameter
    ;

Parameter:
    Type ID
    ;


Condition:
    SimpleIf
    | IfWithElse
    ;


SimpleIf:
    IF Expression COLON StatementList ENDIF


IfWithElse:
    IF Expression COLON StatementList ElseIfList


ElseIfList:
    ELSE COLON StatementList ENDIF {
       
        
    }
    | ELSEIF Expression COLON StatementList ElseIfList 
SwitchStatement:
    SWITCH Expression COLON CaseList ENDSWITCH
    ;

CaseList:
    CaseItems DefaultPart
    ;

CaseItems:
  
    | CaseItems CaseItem
    ;

CaseItem:
    CASE Expression COLON StatementList
    ;

DefaultPart:
  
    | DEFAULT COLON StatementList
    ;


ArrayLiteral:
    LBRACKET RBRACKET {
        $$.type = TYPE_ARRAY;
        ArrayType* arr = createArray();
        if (!arr) {
            yyerror("Failed to create empty array");
            YYERROR;
        }
        $$.data = arr;
        strcpy($$.value, "[]");
    }
    | LBRACKET ExpressionList RBRACKET {
        $$.type = TYPE_ARRAY;
        ArrayType* arr = createArrayFromExprList($2);
        if (!arr) {
            yyerror("Failed to create array from expression list");
            YYERROR;
        }
        $$.data = arr;
        
        // representation string de array
        char arrayStr[MAX_NAME_LENGTH] = "[";
        ExpressionList* current = $2;
        while (current) {
            strncat(arrayStr, current->expr.value, MAX_NAME_LENGTH - strlen(arrayStr) - 1);
            if (current->next) strncat(arrayStr, ",", MAX_NAME_LENGTH - strlen(arrayStr) - 1);
            current = current->next;
        }
        strncat(arrayStr, "]", MAX_NAME_LENGTH - strlen(arrayStr) - 1);
        strncpy($$.value, arrayStr, MAX_NAME_LENGTH - 1);
        $$.value[MAX_NAME_LENGTH - 1] = '\0';
    }
    ;



ExpressionList:
    Expression {
        $$ = createExpressionNode($1);
    }
    | ExpressionList COMMA Expression {
        $$ = addExpressionToList($1, $3);
    }
    ;
DictLiteral:
    LET DICT ID BE LBRACE RBRACE  
    | LET DICT ID BE LBRACE DictItems RBRACE  
    ;

DictItems:
    DictItem  // un seul item
    | DictItems COMMA DictItem  //des items séparés par deux points
    ;

DictItem:
    STRING_LITERAL COLON Expression  // Key-value pair
    ;

%%

/* Gestion des erreurs */
void yyerror(const char *s) {
    if (strcmp(s, "syntax error") == 0) {
        fprintf(stderr, "File '%s', line %d, character %d: syntax error, unexpected '%s'\n", 
                file, yylineno, positionCurseur, yytext);
    } else {
        fprintf(stderr, "File '%s', line %d, character %d: %s\n", 
                file, yylineno, positionCurseur, s);
    }
}

int main(void) {
    // ouverture fichier de test
    yyin = fopen("input.txt", "r");
    if (!yyin) {
        fprintf(stderr, "Error: Could not open input file\n");
        return 1;
    }

    // Creation de la table des symboles
    symbolTable = createSymbolTable();
    listAllSymbols(symbolTable);

    if (!symbolTable) {
        fprintf(stderr, "Error: Failed to create symbol table.\n");
        fclose(yyin);
        return 1;
    }

    // Creation de la pile
    stack = malloc(sizeof(pile));
    if (!stack) {
        fprintf(stderr, "Error: Failed to allocate memory for stack.\n");
        fclose(yyin);
        freeSymbolTable(symbolTable);
        return 1;
    }
    initPile(stack);

    // Affichage du message de demarrage
    printf("Starting syntax analysis...\n");

    // Lancement de l'analyse syntaxique
    int result = yyparse();
    listAllSymbols(symbolTable);

    // Affichage du message de fin
    free(stack);
    // Affichage de table des symboles
    
    // Affichage des quadruplets generes
    afficherQuad(q);

    // Liberation de la table des symboles
    freeSymbolTable(symbolTable);
    
    // Fermeture du fichier
    fclose(yyin);
    
    return result;
    return 0;
}