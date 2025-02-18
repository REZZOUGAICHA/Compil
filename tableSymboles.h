#ifndef TABLE_SYMBOLES_H
#define TABLE_SYMBOLES_H
#include <stddef.h> 
#include <stdlib.h> 
#include <string.h> 
#include <stdio.h> 
#include <stdbool.h>  

#define TYPE_BOOLEAN 0
#define TYPE_INTEGER 1
#define TYPE_FLOAT 2
#define TYPE_STRING 3
#define TYPE_ARRAY 4
#define TYPE_DICT 5
#define MAX_NAME_LENGTH 64  
#define MAX_TYPE_LENGTH 32
#define MAX_VALUE_LENGTH 100  
#define HASH_TABLE_SIZE 101 

typedef struct ArrayType ArrayType;
typedef struct ArrayType {
    size_t length;     
    size_t capacity;    
    char** data;
} ArrayType;


typedef struct SymbolEntry {
    int id;
    char name[MAX_NAME_LENGTH];
    char type[MAX_TYPE_LENGTH];
    char value[MAX_NAME_LENGTH];
    bool isConst;
    bool isInitialized;
    int scopeLevel;
    struct SymbolEntry *next;
} SymbolEntry;

// Structure representant la table des symboles
typedef struct SymbolTable {
    SymbolEntry *buckets[HASH_TABLE_SIZE];
    int nextId;
} SymbolTable;

//Initialise et retourne une nouvelle table des symboles vide.
SymbolTable *createSymbolTable(); 
//Ajoute un nouveau symbole à la table des symboles.
void insertSymbol(SymbolTable *table, const char *name, const char *type,
 const char *value, int scopeLevel, bool isConst, bool isInitialized);
//Recherche un symbole par son nom et son niveau de portée.
SymbolEntry *lookupSymbolByName(SymbolTable *table, const char *name, int scopeLevel);
//Recherche un symbole par son identifiant et son niveau de portée.
SymbolEntry *lookupSymbolById(SymbolTable *table, int id, int scopeLevel);
//Supprime un symbole de la table par son nom.
void deleteSymbolById(SymbolTable *table, int id);
//Supprime un symbole de la table par son identifiant.
void deleteSymbolByName(SymbolTable *table, const char *name);
//Libère la mémoire allouée pour la table des symboles et ses entrées.
void freeSymbolTable(SymbolTable *table);
//Supprime tous les symboles de la table sans libérer la table elle-même.
void clearSymbolTable(SymbolTable *table);
//Vérifie si un symbole existe dans la table par son nom.
int symbolExistsByName(SymbolTable *table, const char *name, int scopeLevel);
//Vérifie si un symbole existe dans la table par son identifiant.
int symbolExistsById(SymbolTable *table, int id, int scopeLevel);
//Affiche le contenu complet de la table des symboles.
void listAllSymbols(SymbolTable *table);
//Met à jour la valeur d'un symbole existant.
void updateSymbolValue(SymbolTable *table, int id,const char *newValue, int scopeLevel);
//Libère la mémoire allouée pour une entrée de la table des symboles.
void freeSymbolEntry(SymbolEntry *entry);

#endif 