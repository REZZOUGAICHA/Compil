## README

This project is a **mini-compiler** developed as part of an academic assignment for the **Compilation module** (2 SIL 2024/2025). The goal of the project is to implement the essential stages of a compiler, including **lexical**, **syntactic**, and **semantic** analysis, following the specifications provided in the project description. It serves as an educational tool for understanding the key concepts in compiler construction.

### Project Overview:

The mini-compiler performs the following tasks:

1. **Lexical Analysis**  
   The first phase of the compilation process, where the source code is read and split into meaningful tokens. This is accomplished using **FLEX**, a tool for generating lexical analyzers. FLEX scans the input program, identifying keywords, variables, operators, and other constructs defined by the language's grammar.

2. **Syntactic Analysis**  
   In this phase, the tokens identified during lexical analysis are parsed to ensure that they follow the correct syntax rules of the language. A **syntax tree** (also known as an Abstract Syntax Tree or AST) is built to represent the structure of the program. Two approaches were used for this:
   - **Custom Implementation:** A syntactic analyzer is implemented from scratch in **C** to handle a subset of the language's grammar. This approach helps to understand the basic concepts of parsing and grammar.
   - **BISON-generated Compiler:** A complete compiler is generated using **BISON**, a parser generator that automates the creation of a syntactic analyzer based on a given grammar.

3. **Semantic Analysis**  
   After the syntax tree is constructed, it is analyzed for semantic errors. This includes checking for issues such as type mismatches, undeclared variables, and invalid operations. The semantic analysis phase ensures that the code is not only syntactically correct but also logically valid. Type checking is performed to ensure that operations are performed on compatible data types.

### Additional Features:

- **Custom Language Creation**  
   The project involves defining a **custom programming language** for which the compiler is built. This includes specifying the syntax, grammar, and semantics of the language, which is then processed by the lexical, syntactic, and semantic analysis phases.

- **Symbol Table Management**  
   A symbol table is maintained throughout the compilation process. This table keeps track of variables, functions, and other identifiers, storing relevant information such as their types and scopes. It is essential for the semantic analysis and error detection phases.

- **Error Handling**  
   The project incorporates robust error handling at various stages of the compilation process. This includes reporting lexical, syntactic, and semantic errors with meaningful error messages to help users debug their code.

### Compilation and Execution Steps

1. **Use Linux Subsystems/OS**:
   ```bash
   wsl
   ```

2. **Build Human-readable Script**
   ```bash
   make humanScript

   ```
4. **Run the Compiler**
```bash
   ./compiler

   ```
    
   
