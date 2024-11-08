%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <time.h>

    // Estados posibles
    typedef enum {V, S, E, I, R} Estado;  // Añadimos el estado V para vacío

    // Estructura para representar una célula
    typedef struct {
        Estado estado;
        float prob_infeccion;
        float prob_exposicion;
        float prob_recuperacion;
        float prob_mortalidad;
        float prob_perdida_inmunidad;  // Nueva probabilidad para la pérdida de inmunidad
    } Celula;

    // Estructura para representar el autómata
    typedef struct {
        Celula **grid;
        int N;
        int id;  // ID del autómata
        int indice_x;  // Índice en la matriz
        int indice_y;
        int contador_S;
        int contador_E;
        int contador_I;
        int contador_R;
        int contador_V;
    } Automata;

    // Estructura para almacenar una matriz de autómatas
    typedef struct {
        Automata ***matriz;  // Cambiamos a matriz bidimensional para facilitar el acceso
        int filas;
        int columnas;
    } MatrizAutomatas;

    MatrizAutomatas *matriz_automatas;

    // Funciones
    void mostrar_cuadriculas_automatas(MatrizAutomatas *matriz);
    void inicializar_grid(Automata *automata);
    int obtener_id(Automata *automata);
    void establecer_id(Automata *automata, int id);
    int contar_vecinos_infectados(MatrizAutomatas *matriz, Automata *automata, int x_celula, int y_celula);
    void simular_paso_automata(MatrizAutomatas *matriz, Automata *automata, Automata *nuevo_automata);
    void agregar_area(Automata *automata, Estado estado, int inicio_fila, int inicio_columna, int filas, int columnas);
    void contar_estados(Automata *automata);
    void mostrar_grid(Automata *automata);
    void mostrar_matriz_automatas(MatrizAutomatas *matriz);
    void mostrar_matriz_ids(MatrizAutomatas *matriz);
    Automata* crear_automata(int id, int N, int indice_x, int indice_y);
    void liberar_automata(Automata *automata);
    MatrizAutomatas* crear_matriz_automatas(int filas, int columnas, int N);
    void liberar_matriz_automatas(MatrizAutomatas *matriz);
    void avanzar_simulacion(MatrizAutomatas *matriz, int tiempo);

    int yylex();
    void yyerror(const char *s);
%}

%union
{
    int ival;
    char *str;
}

%token RELEASE MEMORY CREATE GRID GRIDS ID M N SET AREA CELLS ALL ROWS IROW COLUMNS ICOLUMN PRINT SIMULATION MAKE STEP ENDLINE
%token<ival> NUMBER
%token<str> STATE

%%
input:
    | input create
    | input set
    | input make
    | input print
    | input ENDLINE
    | input release
;

release:
    RELEASE MEMORY ENDLINE
    {
        liberar_matriz_automatas(matriz_automatas);
        printf("\nMemoria liberada con éxito.\n");
    }
;


create:
    grid
;

grid:
    CREATE GRID ROWS NUMBER COLUMNS NUMBER CELLS NUMBER ENDLINE
    // Crear una matriz de ROWxCOLUMNS autómatas, cada autómata de tamaño CELLSxCELLs células
    {
        matriz_automatas = crear_matriz_automatas($4, $6, $8);
        printf("\nAutómata celular asimétrico creado con éxito.\n");
    }
;

set:
    //M = largo de la matriz
    //N = ancho de la matriz
    SET ID NUMBER M NUMBER N NUMBER ENDLINE
    {
        establecer_id(matriz_automatas->matriz[$5][$7], $3);
        printf("\nID del autómata (%d,%d) establecido como %d.\n", $5, $7, $3);
    }
    |
    SET AREA M NUMBER N NUMBER STATE IROW NUMBER ICOLUMN NUMBER ROWS NUMBER COLUMNS NUMBER ENDLINE
    {
        Estado state_new;
        if (strcmp("S",$7) == 0){
            state_new = S;
        }else if (strcmp("I",$7) == 0){
            state_new = I;
        }else if (strcmp("R",$7) == 0){
            state_new = R;
        }else if (strcmp("E",$7) == 0){
            state_new = E;
        }
        agregar_area(matriz_automatas->matriz[$4][$6], state_new, $9, $11, $13, $15);
        printf("\nÁrea de %dx%d celdas con estado %s agregada al autómata (%d,%d).\n", $13, $15, $7, $4, $6);
    } 
;

print: 
    PRINT ALL ID ENDLINE
    {
        mostrar_matriz_ids(matriz_automatas);
    }
    | PRINT GRIDS ENDLINE
    {
       mostrar_cuadriculas_automatas(matriz_automatas);
    }
;

make:
    MAKE SIMULATION STEP ENDLINE //avanzar un tiempo
    {   
        printf("\nAvanzar simulación un tiempo:\n");
        avanzar_simulacion(matriz_automatas, 1);
        printf("\nResultados de la simulación:\n");
        mostrar_matriz_automatas(matriz_automatas);
        mostrar_cuadriculas_automatas(matriz_automatas);
    }
    | MAKE SIMULATION STEP NUMBER ENDLINE //avanzar "number" tiempos
    {
        printf("\nAvanzar simulación %d tiempos:\n", $4);
        avanzar_simulacion(matriz_automatas, $4);
        printf("\nResultados de la simulación:\n");
        mostrar_matriz_automatas(matriz_automatas);
        mostrar_cuadriculas_automatas(matriz_automatas);
    }
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

void mostrar_cuadriculas_automatas(MatrizAutomatas *matriz){
    // Mostrar las cuadrículas de los autómatas
    for (int i = 0; i < matriz->filas; i++) {
        for (int j = 0; j < matriz->columnas; j++) {
            printf("\nCuadrícula del autómata (%d,%d) con ID %d:\n", i, j, matriz->matriz[i][j]->id);
            mostrar_grid(matriz->matriz[i][j]);
        }
    }
}
// Función para inicializar toda la cuadrícula del autómata como vacía
void inicializar_grid(Automata *automata) {
    automata->contador_S = automata->contador_E = automata->contador_I = automata->contador_R = automata->contador_V = 0;
    for (int i = 0; i < automata->N; i++) {
        for (int j = 0; j < automata->N; j++) {
            automata->grid[i][j].estado = V;
            automata->grid[i][j].prob_infeccion = 0.1;
            automata->grid[i][j].prob_exposicion = 0.2;
            automata->grid[i][j].prob_recuperacion = 0.1;
            automata->grid[i][j].prob_mortalidad = 0.05;
            automata->grid[i][j].prob_perdida_inmunidad = 0.01;
            automata->contador_V++;
        }
    }
}

// Funciones para obtener y establecer el ID de un autómata
int obtener_id(Automata *automata) {
    return automata->id;
}

void establecer_id(Automata *automata, int id) {
    automata->id = id;
}

// Función para contar vecinos infectados considerando vecinos en autómatas adyacentes con el mismo ID
int contar_vecinos_infectados(MatrizAutomatas *matriz, Automata *automata, int x_celula, int y_celula) {
    int N = automata->N;
    int infectados = 0;

    // Direcciones en la vecindad de Moore
    int direcciones[8][2] = {
        {-1, -1}, {-1, 0}, {-1, 1}, 
        {0, -1},          {0, 1},
        {1, -1},  {1, 0},  {1, 1}
    };

    for (int d = 0; d < 8; d++) {
        int nx = x_celula + direcciones[d][0];
        int ny = y_celula + direcciones[d][1];

        Automata *automata_vecino = automata;
        int indice_x = automata->indice_x;
        int indice_y = automata->indice_y;

        // Si la célula vecina está fuera de los límites del autómata actual
        if (nx < 0 || nx >= N || ny < 0 || ny >= N) {
            int dx_automata = 0;
            int dy_automata = 0;
            if (nx < 0) dx_automata = -1;
            if (nx >= N) dx_automata = 1;
            if (ny < 0) dy_automata = -1;
            if (ny >= N) dy_automata = 1;

            int vecino_x = indice_x + dx_automata;
            int vecino_y = indice_y + dy_automata;

            // Verificamos si el autómata vecino existe
            if (vecino_x >= 0 && vecino_x < matriz->filas && vecino_y >= 0 && vecino_y < matriz->columnas) {
                automata_vecino = matriz->matriz[vecino_x][vecino_y];
                if (automata_vecino->id != automata->id) continue;  // Solo consideramos vecinos con el mismo ID
                // Ajustamos nx y ny para que apunten a la célula correcta en el autómata vecino
                if (nx < 0) nx = N - 1;
                if (nx >= N) nx = 0;
                if (ny < 0) ny = N - 1;
                if (ny >= N) ny = 0;
            } else {
                continue;  // No hay autómata vecino, continuamos
            }
        }

        Celula *celula_vecina = &automata_vecino->grid[nx][ny];
        if (celula_vecina->estado == I) {
            infectados++;
        }
    }
    return infectados;
}

// Función para simular un paso en un autómata considerando vecinos
void simular_paso_automata(MatrizAutomatas *matriz, Automata *automata, Automata *nuevo_automata) {
    int N = automata->N;
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            Celula *celula_actual = &automata->grid[i][j];
            Celula *celula_nueva = &nuevo_automata->grid[i][j];
            *celula_nueva = *celula_actual;

            int infectados = contar_vecinos_infectados(matriz, automata, i, j);
            float random_value = rand() / (float)RAND_MAX;

            switch (celula_actual->estado) {
                case S:
                    if (infectados > 0 && random_value < celula_actual->prob_exposicion) {
                        celula_nueva->estado = E;
                    }
                    break;
                case E:
                    if (random_value < celula_actual->prob_infeccion) {
                        celula_nueva->estado = I;
                    }
                    break;
                case I:
                    if (random_value < celula_actual->prob_recuperacion) {
                        celula_nueva->estado = R;
                    } else if (random_value < celula_actual->prob_mortalidad) {
                        celula_nueva->estado = S;
                    }
                    break;
                case R:
                    if (random_value < celula_actual->prob_perdida_inmunidad) {
                        celula_nueva->estado = S;
                    }
                    break;
                case V:
                    // No hacer nada
                    break;
            }
        }
    }
}

// Función para agregar un área rectangular con un estado específico en el autómata
void agregar_area(Automata *automata, Estado estado, int inicio_fila, int inicio_columna, int filas, int columnas) {
    for (int i = inicio_fila; i < inicio_fila + filas && i < automata->N; i++) {
        for (int j = inicio_columna; j < inicio_columna + columnas && j < automata->N; j++) {
            automata->grid[i][j].estado = estado;
            // Actualizar contadores
            switch (estado) {
                case S: automata->contador_S++; break;
                case E: automata->contador_E++; break;
                case I: automata->contador_I++; break;
                case R: automata->contador_R++; break;
                case V: automata->contador_V++; break;
            }
        }
    }
}

// Función para contar los estados en un autómata específico
void contar_estados(Automata *automata) {
    automata->contador_S = automata->contador_E = automata->contador_I = automata->contador_R = automata->contador_V = 0;
    for (int i = 0; i < automata->N; i++) {
        for (int j = 0; j < automata->N; j++) {
            switch (automata->grid[i][j].estado) {
                case S: automata->contador_S++; break;
                case E: automata->contador_E++; break;
                case I: automata->contador_I++; break;
                case R: automata->contador_R++; break;
                case V: automata->contador_V++; break;
            }
        }
    }
}

// Función para imprimir la cuadrícula de un autómata específico
void mostrar_grid(Automata *automata) {
    for (int i = 0; i < automata->N; i++) {
        for (int j = 0; j < automata->N; j++) {
            switch(automata->grid[i][j].estado) {
                case V: printf("  "); break;
                case S: printf("S "); break;
                case E: printf("E "); break;
                case I: printf("I "); break;
                case R: printf("R "); break;
            }
        }
        printf("\n");
    }
}

// Función para mostrar la matriz de autómatas con el conteo de cada estado en cada autómata
void mostrar_matriz_automatas(MatrizAutomatas *matriz) {
    printf("Matriz de autómatas:\n");
    for (int i = 0; i < matriz->filas; i++) {
        for (int j = 0; j < matriz->columnas; j++) {
            Automata *automata = matriz->matriz[i][j];
            // Contar estados antes de imprimir
            contar_estados(automata);
            printf("Autómata (%d,%d) ID: %d | S: %d | E: %d | I: %d | R: %d | V: %d\n",
                   i, j, automata->id, automata->contador_S, automata->contador_E, automata->contador_I, automata->contador_R, automata->contador_V);
        }
        printf("\n");
    }
}

// Función para mostrar la matriz de IDs de autómatas
void mostrar_matriz_ids(MatrizAutomatas *matriz) {
    printf("\nMatriz de IDs de Autómatas:\n");
    for (int i = 0; i < matriz->filas; i++) {
        for (int j = 0; j < matriz->columnas; j++) {
            Automata *automata = matriz->matriz[i][j];
            printf("ID:%2d ", automata->id);
        }
        printf("\n");
    }
    printf("\n");
}

// Función para inicializar un autómata con una cuadrícula de células
Automata* crear_automata(int id, int N, int indice_x, int indice_y) {
    Automata *automata = (Automata*)malloc(sizeof(Automata));
    automata->id = id;
    automata->N = N;
    automata->indice_x = indice_x;
    automata->indice_y = indice_y;
    automata->grid = (Celula**)malloc(N * sizeof(Celula*));
    for (int i = 0; i < N; i++) {
        automata->grid[i] = (Celula*)malloc(N * sizeof(Celula));
    }
    inicializar_grid(automata);
    return automata;
}

// Función para liberar la memoria de un autómata
void liberar_automata(Automata *automata) {
    for (int i = 0; i < automata->N; i++) {
        free(automata->grid[i]);
    }
    free(automata->grid);
    free(automata);
}

// Función para inicializar la matriz de autómatas
MatrizAutomatas* crear_matriz_automatas(int filas, int columnas, int N) {
    MatrizAutomatas *matriz = (MatrizAutomatas*)malloc(sizeof(MatrizAutomatas));
    matriz->filas = filas;
    matriz->columnas = columnas;
    matriz->matriz = (Automata***)malloc(filas * sizeof(Automata**));

    for (int i = 0; i < filas; i++) {
        matriz->matriz[i] = (Automata**)malloc(columnas * sizeof(Automata*));
        for (int j = 0; j < columnas; j++) {
            int id = 1;  // Puedes cambiar el ID según tus necesidades
            matriz->matriz[i][j] = crear_automata(id, N, i, j);
        }
    }
    return matriz;
}

// Función para liberar la memoria de la matriz de autómatas
void liberar_matriz_automatas(MatrizAutomatas *matriz) {
    for (int i = 0; i < matriz->filas; i++) {
        for (int j = 0; j < matriz->columnas; j++) {
            liberar_automata(matriz->matriz[i][j]);
        }
        free(matriz->matriz[i]);
    }
    free(matriz->matriz);
}

// Función para avanzar la simulación
void avanzar_simulacion(MatrizAutomatas *matriz, int tiempo) {
    // Creamos una copia de los autómatas para almacenar los nuevos estados
    Automata ***nuevos_automatas = (Automata ***)malloc(matriz->filas * sizeof(Automata **));
    for (int i = 0; i < matriz->filas; i++) {
        nuevos_automatas[i] = (Automata **)malloc(matriz->columnas * sizeof(Automata *));
        for (int j = 0; j < matriz->columnas; j++) {
            Automata *automata = matriz->matriz[i][j];
            nuevos_automatas[i][j] = crear_automata(automata->id, automata->N, automata->indice_x, automata->indice_y);
        }
    }

    for (int t = 0; t < tiempo; t++) {
        printf("\nTiempo: %d\n", t + 1);

        // Actualización de las células considerando vecinos
        for (int i = 0; i < matriz->filas; i++) {
            for (int j = 0; j < matriz->columnas; j++) {
                Automata *automata = matriz->matriz[i][j];
                Automata *nuevo_automata = nuevos_automatas[i][j];
                simular_paso_automata(matriz, automata, nuevo_automata);
            }
        }

        // Actualizamos los autómatas con los nuevos estados
        for (int i = 0; i < matriz->filas; i++) {
            for (int j = 0; j < matriz->columnas; j++) {
                Automata *automata = matriz->matriz[i][j];
                Automata *nuevo_automata = nuevos_automatas[i][j];
                // Actualizamos el grid del autómata
                for (int x = 0; x < automata->N; x++) {
                    for (int y = 0; y < automata->N; y++) {
                        automata->grid[x][y] = nuevo_automata->grid[x][y];
                    }
                }
            }
        }
        mostrar_matriz_automatas(matriz);
        mostrar_cuadriculas_automatas(matriz);
    }

    // Liberamos la memoria de los nuevos autómatas
    for (int i = 0; i < matriz->filas; i++) {
        for (int j = 0; j < matriz->columnas; j++) {
            liberar_automata(nuevos_automatas[i][j]);
        }
        free(nuevos_automatas[i]);
    }
    free(nuevos_automatas);
}

int main(int argc, char **argv)
{
    srand(time(NULL));
    yyparse();
    return 0;
}
