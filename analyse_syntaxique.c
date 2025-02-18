#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "tableSymboles.h" 
#include <ctype.h>
#define MAX_SYMBOLES 100
#define MAX_TERMINALS 100
#define MAX_REGLES 100
#define TALLE_MAX_ENSEMBLE 100
#define TAILLE_MAX_PILE 100
#define TAILLE_MAX_INPUT 1000

typedef struct {
    char* elements[TALLE_MAX_ENSEMBLE];
    int size;
} ensemble_symbole;

typedef struct {
    char* nonTerminal;
    char* terminal;
    char* production;
} entree_tab_analyse;

typedef struct {
    entree_tab_analyse* entree;
    int numEntrees;
    char** terminals;
    int numTerminals;
    char** nonTerminals;
    int numNonTerminals;
    ensemble_symbole* debut;   
    ensemble_symbole* suivant;   
} Table_analyse;

typedef struct {
    char* items[TAILLE_MAX_PILE];
    int top;
} pile_analyse;

void init_pile(pile_analyse* pile) {
    pile->top = -1;
}

void empiler(pile_analyse* pile, const char* item) {
    if (pile->top < TAILLE_MAX_PILE - 1) {
        pile->items[++pile->top] = strdup(item);
    }
}

char* depiler(pile_analyse* pile) {
    if (pile->top >= 0) {
        return pile->items[pile->top--];
    }
    return NULL;
}

char* sommet_pile(pile_analyse* pile) {
    if (pile->top >= 0) {
        return pile->items[pile->top];
    }
    return NULL;
}

void initensemble(ensemble_symbole* ensemble) {
    ensemble->size = 0;
}

void ajouter_a_ensemble(ensemble_symbole* ensemble, const char* element) {
    for (int i = 0; i < ensemble->size; i++) {
        if (strcmp(ensemble->elements[i], element) == 0) return;
    }     
    ensemble->elements[ensemble->size] = strdup(element);
    ensemble->size++;
}

Table_analyse* initialiser_table_analyse() {
    Table_analyse* table = (Table_analyse*)malloc(sizeof(Table_analyse));
    table->entree = (entree_tab_analyse*)malloc(MAX_REGLES * sizeof(entree_tab_analyse));
    table->terminals = (char**)malloc(MAX_TERMINALS * sizeof(char*));
    table->nonTerminals = (char**)malloc(MAX_SYMBOLES * sizeof(char*));
    table->debut = (ensemble_symbole*)malloc(MAX_SYMBOLES * sizeof(ensemble_symbole));
    table->suivant = (ensemble_symbole*)malloc(MAX_SYMBOLES * sizeof(ensemble_symbole));
    
    for (int i = 0; i < MAX_SYMBOLES; i++) {
        initensemble(&table->debut[i]);
        initensemble(&table->suivant[i]);
    }
    
    table->numEntrees = 0;
    table->numTerminals = 0;
    table->numNonTerminals = 0;
    return table;
}

void DebutSuivant(Table_analyse* table) {
    int idxZ = 0;  // Index  Z
    int idxS = 1;  // Index S
    int idxA = 2;  // Index A
    int idxB = 3;  // Index B

    // DEBUT(A)
    ajouter_a_ensemble(&table->debut[idxA], "int");
    ajouter_a_ensemble(&table->debut[idxA], "str");
    ajouter_a_ensemble(&table->debut[idxA], "const");
    ajouter_a_ensemble(&table->debut[idxA], "float");
    ajouter_a_ensemble(&table->debut[idxA], "bool");
    ajouter_a_ensemble(&table->debut[idxA], "array");
    ajouter_a_ensemble(&table->debut[idxA], "dict");

    // DEBUT(B)
    ajouter_a_ensemble(&table->debut[idxB], "ID");

    // DEBUT(S) = DEBUT(A)
    for (int i = 0; i < table->debut[idxA].size; i++) {
        ajouter_a_ensemble(&table->debut[idxS], table->debut[idxA].elements[i]);
    }

    // DEBUT(Z) = DEBUT(S)
    for (int i = 0; i < table->debut[idxS].size; i++) {
        ajouter_a_ensemble(&table->debut[idxZ], table->debut[idxS].elements[i]);
    }

    // SUIVANT 
    ajouter_a_ensemble(&table->suivant[idxZ], "#");    // SUIVANT(Z) = {#}
    ajouter_a_ensemble(&table->suivant[idxS], "#");    // SUIVANT(S) = {#}
    ajouter_a_ensemble(&table->suivant[idxA], "ID");   // SUIVANT(A) = {ID}
    ajouter_a_ensemble(&table->suivant[idxB], "#");    // SUIVANT(B) = {#}
}


void ajouter_entree_table_analyse(Table_analyse* table, const char* nonTerminal, const char* terminal, const char* production) {
    entree_tab_analyse entry;
    entry.nonTerminal = strdup(nonTerminal);
    entry.terminal = strdup(terminal);
    entry.production = strdup(production);
    table->entree[table->numEntrees++] = entry;
}

void creer_table_analyse(Table_analyse* table) {
    const char* nonTerminals[] = {"Z", "S", "A", "B"};
    for (int i = 0; i < 4; i++) {
        table->nonTerminals[i] = strdup(nonTerminals[i]);
    }
    table->numNonTerminals = 4;

    const char* terminals[] = {"int", "str", "const", "float", "bool", "array", "dict", "ID", "#"};
    for (int i = 0; i < 9; i++) {
        table->terminals[i] = strdup(terminals[i]);
    }
    table->numTerminals = 9;

    DebutSuivant(table);

    // Z -> S #
    for (int i = 0; i < table->debut[0].size; i++) {
        ajouter_entree_table_analyse(table, "Z", table->debut[0].elements[i], "S #");
    }
    
    // S -> A B
    for (int i = 0; i < table->debut[2].size; i++) {
        ajouter_entree_table_analyse(table, "S", table->debut[2].elements[i], "A B");
    }

    ajouter_entree_table_analyse(table, "A", "int", "int");
    ajouter_entree_table_analyse(table, "A", "str", "str");
    ajouter_entree_table_analyse(table, "A", "const", "const");
    ajouter_entree_table_analyse(table, "A", "float", "float");
    ajouter_entree_table_analyse(table, "A", "bool", "bool");
    ajouter_entree_table_analyse(table, "A", "array", "array");
    ajouter_entree_table_analyse(table, "A", "dict", "dict");

    // B -> ID
    ajouter_entree_table_analyse(table, "B", "ID", "ID");
}


void afficher_ensemble(const char* nom_ensemble, ensemble_symbole* ensemble) {
    printf("%s: { ", nom_ensemble);
    for (int i = 0; i < ensemble->size; i++) {
        printf("%s", ensemble->elements[i]);
        if (i < ensemble->size - 1) printf(", ");
    }
    printf(" }\n");
}

void afficher_debuts(Table_analyse* table) {
    printf("\nEnsembles DEBUT:\n");
    for (int i = 0; i < table->numNonTerminals; i++) {
        afficher_ensemble(table->nonTerminals[i], &table->debut[i]);
    }
}

void affichier_suivants(Table_analyse* table) {
    printf("\nEnsembles SUIVANT:\n");
    for (int i = 0; i < table->numNonTerminals; i++) {
        afficher_ensemble(table->nonTerminals[i], &table->suivant[i]);
    }
}
void afficher_table_analyse(Table_analyse* table) {
    printf("\nTable d'analyse syntaxique:\n\n");
    // En-tête
    printf("%-12s", "");
    for (int i = 0; i < table->numTerminals; i++) {
        printf("%-12s", table->terminals[i]);
    }
    printf("\n");
    // Ligne de séparation
    for (int i = 0; i < (table->numTerminals + 1) * 12; i++) {
        printf("-");
    }
    printf("\n");
    // Corps de la table
    for (int i = 0; i < table->numNonTerminals; i++) {
        printf("%-12s", table->nonTerminals[i]);
        for (int j = 0; j < table->numTerminals; j++) {
            bool found = false;
            for (int k = 0; k < table->numEntrees; k++) {
                if (strcmp(table->entree[k].nonTerminal, table->nonTerminals[i]) == 0 &&
                    strcmp(table->entree[k].terminal, table->terminals[j]) == 0) {
                    printf("%-12s", table->entree[k].production);
                    found = true;
                    break;
                }
            }
            if (!found) {
                printf("%-12s", "erreur");
            }
        }
        printf("\n");
    }
}
void liberer_table_analyse(Table_analyse* table) {
    for (int i = 0; i < table->numEntrees; i++) {
        free(table->entree[i].nonTerminal);
        free(table->entree[i].terminal);
        free(table->entree[i].production);
    }
    for (int i = 0; i < table->numTerminals; i++) {
        free(table->terminals[i]);
    }
    for (int i = 0; i < table->numNonTerminals; i++) {
        free(table->nonTerminals[i]);
        for (int j = 0; j < table->debut[i].size; j++) {
            free(table->debut[i].elements[j]);
        }
        for (int j = 0; j < table->suivant[i].size; j++) {
            free(table->suivant[i].elements[j]);
        }
    }
    free(table->entree);
    free(table->terminals);
    free(table->nonTerminals);
    free(table->debut);
    free(table->suivant);
    free(table);
}
const char* lire_table_analyse(Table_analyse* table, const char* nonTerminal, const char* terminal) {
    // Parcours des entrées de la table
    for (int i = 0; i < table->numEntrees; i++) {
        // Si une entrée correspond à la combinaison non-terminal/terminal
        if (strcmp(table->entree[i].nonTerminal, nonTerminal) == 0 &&
            strcmp(table->entree[i].terminal, terminal) == 0) {
            // Retourne la production associée
            return table->entree[i].production;
        }
    }
    // Si aucune entrée ne correspond, retourne "erreur"
    return "erreur";
}

typedef struct {
    char** tokens;
    int nb_token;
} tableau_tokens;

bool identifiant_valide(const char* id) {
    if (!id || strlen(id) == 0) return false;
    
    if (!isalpha(id[0]) && id[0] != '_') return false;
    
    for (int i = 1; id[i] != '\0'; i++) {
        if (!isalnum(id[i]) && id[i] != '_') return false;
    }
    
    const char* mots_cles[] = {"int", "str", "const", "float", "bool", "array", "dict", "ID"};
    int nb_mots_cles = sizeof(mots_cles) / sizeof(mots_cles[0]);
    for (int i = 0; i < nb_mots_cles; i++) {
        if (strcasecmp(id, mots_cles[i]) == 0) return false;
    }
    return true;
}

tableau_tokens decouper_input(const char* input) {
    tableau_tokens result = {malloc(TAILLE_MAX_INPUT * sizeof(char*)), 0};
    char* copie_input = strdup(input);
    char* token = strtok(copie_input, " \t\n");
    while (token != NULL) {
        if (result.nb_token > 0 && 
            strcmp(result.tokens[result.nb_token-1], "ID") != 0 && 
            identifiant_valide(token)) {
            char* identifier = strdup(token);
            result.tokens[result.nb_token++] = strdup("ID");
            // On remplace notre token par ID et on le met dans le tableau de token
            result.tokens[result.nb_token++] = identifier;
            // On stocke le vrai identifiant
        } 
        else {
            result.tokens[result.nb_token++] = strdup(token);
        }
        token = strtok(NULL, " \t\n");
    }
     
    free(copie_input);
    return result;
}

bool reconnaissance(Table_analyse* table, const char* input, SymbolTable* symTable) {
    pile_analyse pile;
    init_pile(&pile);
    empiler(&pile, "#");
    empiler(&pile, "Z");
    
    tableau_tokens tokens = decouper_input(input);
    int symbole_courant = 0;
    // ajouter le # a la fin de la chaine d'entree
    tokens.tokens[tokens.nb_token] = strdup("#");
    tokens.nb_token++;
    
    char* id_courant = NULL;
    char* type_courant = NULL;
    while (pile.top >= 0) {
        char* X = sommet_pile(&pile);
        char* a = tokens.tokens[symbole_courant];
        if (strcmp(X, "#") == 0 && strcmp(a, "#") == 0) 
        {
            printf("La chaine est syntaxiquement correcte !\n");
            if (type_courant != NULL && id_courant != NULL) {
                insertSymbol(symTable, id_courant, type_courant, NULL, 0,0,1);
            }
            return true;
        }
        
        bool terminal = false;
        for (int i = 0; i < table->numTerminals; i++) {
            if (strcmp(X, table->terminals[i]) == 0) {
                terminal = true;
                break;
            }
        }
        
        if (terminal) {
            if (strcmp(X, a) != 0 )
            {
                printf("Erreur\n");
                return false;
            } 
            else 
            {
                if (strcmp(X, "int") == 0 || strcmp(X, "float") == 0 ||
                    strcmp(X, "str") == 0 || strcmp(X, "bool") == 0 ||
                    strcmp(X, "array") == 0 || strcmp(X, "dict") == 0 || strcmp(X, "const") == 0) {
                    type_courant = strdup(X);
                }
                if (strcmp(X, "ID") == 0 && symbole_courant + 1 < tokens.nb_token) {
                    id_courant = strdup(tokens.tokens[symbole_courant + 1]);
                    symbole_courant++; 
                }
                
                free(depiler(&pile));
                // ON Ignore le prochain token car on l'a changé par ID  
                symbole_courant++;
                continue;
            }
        } 
        
        const char* production = lire_table_analyse(table, X, a);
        
        if (strcmp(production, "erreur") == 0) {
            printf("Erreur! %s \n", a);
            return false;
        }
        
        free(depiler(&pile));
        char* production_Copie = strdup(production);
        char* symbol = strtok(production_Copie, " ");
        char* symboles_production[TAILLE_MAX_PILE];
        int nb_symboles = 0;
        while (symbol != NULL) {
            symboles_production[nb_symboles++] = strdup(symbol);
            symbol = strtok(NULL, " ");
        }
        
        for (int i = nb_symboles - 1; i >= 0; i--) {
            if (strcmp(symboles_production[i], "ε") != 0) {
                empiler(&pile, symboles_production[i]);
            }
            free(symboles_production[i]);
        }
        
        free(production_Copie);
    }
    
    if (type_courant) free(type_courant);
    if (id_courant) free(id_courant);
    for (int i = 0; i < tokens.nb_token; i++) {
        free(tokens.tokens[i]);
    }
    free(tokens.tokens);
    
    return false;
}
int main() {
    Table_analyse* table = initialiser_table_analyse();
    creer_table_analyse(table);
    
    SymbolTable* symTable = createSymbolTable();
    char input[1000];
    printf("Donner déclaration :  ");
    fgets(input, sizeof(input), stdin);
    input[strcspn(input, "\n")] = 0;  
    if (reconnaissance(table, input, symTable)) {
        afficher_debuts(table);
        affichier_suivants(table);
        afficher_table_analyse(table);
        printf("\nTable de symbole apres analyse:\n");
        listAllSymbols(symTable);
    }
    
  
    liberer_table_analyse(table);
    
    return 0;
}