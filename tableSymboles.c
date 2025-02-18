#include "tableSymboles.h"

unsigned int hash(const char *name) {
    unsigned int hashValue = 0;
    for (int i = 0; name[i] != '\0'; i++) {
        hashValue = 31 * hashValue + name[i];
    }
    return hashValue % HASH_TABLE_SIZE;
}
//Initialise et retourne une nouvelle table des symboles vide.



SymbolTable *createSymbolTable() {
    SymbolTable *table = (SymbolTable *)malloc(sizeof(SymbolTable));
    if (table == NULL) {
        return NULL;
    }
    memset(table->buckets, 0, sizeof(table->buckets));
    table->nextId = 0;
    return table;
}

void insertSymbol(SymbolTable *table, const char *name, const char *type, 
                 const char *value, int scopeLevel, bool isConst, bool isInitialized) {
    if (!table || !name || !type) {
        return;
    }

    SymbolEntry *entry = (SymbolEntry *)malloc(sizeof(SymbolEntry));
    if (!entry) {
        return;
    }

    memset(entry, 0, sizeof(SymbolEntry));

    entry->id = table->nextId++;
    entry->scopeLevel = scopeLevel;
    entry->isConst = isConst;
    entry->isInitialized = isInitialized;
    strncpy(entry->name, name, MAX_NAME_LENGTH - 1);
    strncpy(entry->type, type, MAX_TYPE_LENGTH - 1);
    if (value) {
        strncpy(entry->value, value, MAX_NAME_LENGTH - 1);
    }

    unsigned int index = hash(name);
    entry->next = table->buckets[index];
    table->buckets[index] = entry;
}
//retourne l'entré de la table 
SymbolEntry *lookupSymbolByName(SymbolTable *table, const char *name, int scopeLevel) {
    if (!table || !name) {
        return NULL;
    }

    unsigned int index = hash(name);
    SymbolEntry *entry = table->buckets[index];

    while (entry) {
        if (strcmp(entry->name, name) == 0 && entry->scopeLevel == scopeLevel) {
            return entry;
        }
        entry = entry->next;
    }

    if (scopeLevel == 1) {
        entry = table->buckets[index];
        while (entry) {
            if (strcmp(entry->name, name) == 0 && entry->scopeLevel == 0) {
                return entry;
            }
            entry = entry->next;
        }
    }

    return NULL;
}

SymbolEntry *lookupSymbolById(SymbolTable *table, int id, int scopeLevel) {
    if (!table) {
        return NULL;
    }

    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *entry = table->buckets[i];
        while (entry) {
            if (entry->id == id && 
                (entry->scopeLevel == scopeLevel || 
                 (scopeLevel == 1 && entry->scopeLevel == 0))) {
                return entry;
            }
            entry = entry->next;
        }
    }
    return NULL;
}

void clearSymbolTable(SymbolTable *table) {
    if (!table) {
        return;
    }

    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            SymbolEntry *next = current->next;
            free(current);
            current = next;
        }
        table->buckets[i] = NULL;
    }
    table->nextId = 0;
}

void freeSymbolTable(SymbolTable *table) {
    if (table) {
        clearSymbolTable(table);
        free(table);
    }
}

void deleteSymbolByName(SymbolTable *table, const char *name) {
    if (!table || !name) {
        return;
    }

    unsigned int index = hash(name);
    SymbolEntry *current = table->buckets[index];
    SymbolEntry *prev = NULL;

    while (current) {
        if (strcmp(current->name, name) == 0) {
            if (prev) {
                prev->next = current->next;
            } else {
                table->buckets[index] = current->next;
            }
            free(current);
            return;
        }
        prev = current;
        current = current->next;
    }
}

void deleteSymbolById(SymbolTable *table, int id) {
    if (!table) {
        return;
    }

    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        SymbolEntry *prev = NULL;

        while (current) {
            if (current->id == id) {
                if (prev) {
                    prev->next = current->next;
                } else {
                    table->buckets[i] = current->next;
                }
                free(current);
                return;
            }
            prev = current;
            current = current->next;
        }
    }
}

void listAllSymbols(SymbolTable *table) {
    if (!table) {
        return;
    }

    printf("\nSymbol Table Contents:\n");
    printf("ID\tName\tType\tScope\tValue\n");
    printf("----------------------------------------\n");

    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        SymbolEntry *current = table->buckets[i];
        while (current) {
            if (strncmp(current->type, "array", 5) == 0) {
                // Print array values in a formatted way
                printf("%d\t%s\t%s\t%d\t", 
                    current->id,
                    current->name,
                    current->type,
                    current->scopeLevel);
                
                // Parse and print array values from the quadruplet
                char *value = current->value;
                char *token = strtok(value, ",");
                int first = 1;
                
                while (token != NULL) {
                    if (!first) {
                        printf(",");
                    }
                    printf("%s", token);
                    first = 0;
                    token = strtok(NULL, ",");
                }
                
            } else {
                printf("%d\t%s\t%s\t%d\t%s\n",
                    current->id,
                    current->name,
                    current->type,
                    current->scopeLevel,
                    current->isInitialized ? current->value : "(uninitialized)");
            }
            current = current->next;
        }
    }
}


void updateSymbolValue(SymbolTable *table, int id, const char *newValue, int scopeLevel) {
    if (!table || !newValue) {
        return;
    }

    SymbolEntry *entry = lookupSymbolById(table, id, scopeLevel);
    if (!entry || entry->isConst) {
        return;
    }

    strncpy(entry->value, newValue, MAX_NAME_LENGTH - 1);
    entry->value[MAX_NAME_LENGTH - 1] = '\0';
    entry->isInitialized = true;
}


int symbolExistsByName(SymbolTable *table, const char *name, int scopeLevel) {
    return lookupSymbolByName(table, name, scopeLevel) != NULL;
}
