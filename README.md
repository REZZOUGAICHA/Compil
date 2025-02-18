### Compilation and Execution Steps

1. **Use Linux Subsystems**:
   ```bash
   wsl
   ```

2. **Generate the syntax analysis files** using Bison:
   ```bash
   bison -d syntaxique.y
   ```

3. **Generate the lexical analysis files** using Flex:
   ```bash
   flex lexical.l
   ```

4. **Compile the generated files** into an executable named `compiler`:
   ```bash
   gcc lex.yy.c syntaxique.tab.c -o compiler
   ```

5. **Run the compiler**:
   ```bash
   ./compiler
   ```

6. **Compile the syntax analysis program**:
   ```bash
   gcc analyse_syntaxique.c tableSymboles.c -o analyse_syntaxique
   ```

7. **Run the syntax analysis program**:
   ```bash
   ./analyse_syntaxique
   ```