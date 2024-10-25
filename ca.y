%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

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

    Celula **grid;  // Cuadrícula dinámica de células
    int N = 20;

    void inicializar_grid(int N, float prob_infeccion, float prob_exposicion, float prob_recuperacion, float prob_mortalidad, float prob_perdida_inmunidad);
    void crear_grilla(int N, Estado id_area, int inicio_fila, int inicio_columna, int filas, int columnas);
    void mostrar_grid(int N);
    int contar_infectados(int N, int x, int y);
    Estado actualizar_estado(int N, int x, int y);
    void simular_paso(int N);
    
    int yylex();
    void yyerror(const char *s);
%}

%union
{
    int ival;
    float fval;
    char *str;
}

%token CREATE GRID SUBGRID ROWS IROW COLUMNS ICOLUMN PRINT SIMULATION MAKE STEP ENDLINE EXPOSITION INFECT RECOVER MORTALITY IMMUNITY
%token<ival> NUMBER
%token<fval> NUMBERF
%token<str> STATE

%%
input:
    | input create
    | input make
    | input print
    | input ENDLINE
;

create:
    grid
    |subgrid
;

grid:
    CREATE GRID INFECT NUMBERF EXPOSITION NUMBERF RECOVER NUMBERF MORTALITY NUMBERF IMMUNITY NUMBERF ENDLINE
    {
        inicializar_grid(N, $4, $6, $8, $10, $12);
        printf("\nAutómata celular asimétrico creado con éxito.\n");
    }
;

subgrid:
    CREATE SUBGRID STATE IROW NUMBER ICOLUMN NUMBER ROWS NUMBER COLUMNS NUMBER ENDLINE
    {   
        Estado state_new;
        if (strcmp("S",$3) == 0){
            state_new = S;
        }else if (strcmp("I",$3) == 0){
            state_new = I;
        }else if (strcmp("R",$3) == 0){
            state_new = R;
        }
        
        crear_grilla(N, state_new, $5, $7, $9, $11);  // Crear un área de $9x$11 celdas susceptibles a partir de ($5,$7)
        printf("\nAutómata celular de %dx%d creado.\n", $9, $11);
    }
;

print: PRINT ENDLINE
    {
        printf("\nEstado actuál del autómata celular asimétrico:\n");
        mostrar_grid(N);   
    }
;

make:
    MAKE SIMULATION STEP ENDLINE //avanzar un tiempo
    {   
        printf("\nAvanzar simulación un tiempo:\n");
        simular_paso(N);
        mostrar_grid(N);
    }
    | MAKE SIMULATION STEP NUMBER ENDLINE //avanzar "number" tiempos
    {
        // Simular T pasos
        for (int t = 0; t < $4; t++) {  // Simular $4 pasos
            printf("\nPaso %d:\n", t + 1);
            simular_paso(N);
            mostrar_grid(N);
        }
    }
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

// Función para inicializar toda la cuadrícula como vacía (por defecto)
void inicializar_grid(int N, float prob_infeccion, float prob_exposicion, float prob_recuperacion, float prob_mortalidad, float prob_perdida_inmunidad) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            grid[i][j].estado = V;  // Inicialmente todas las celdas serán vacías
            // Inicialización de probabilidades para cada célula
            grid[i][j].prob_infeccion = prob_infeccion;
            grid[i][j].prob_exposicion = prob_exposicion;
            grid[i][j].prob_recuperacion = prob_recuperacion;
            grid[i][j].prob_mortalidad = prob_mortalidad;
            grid[i][j].prob_perdida_inmunidad = prob_perdida_inmunidad;  // Pérdida de inmunidad
        }
    }
}

// Función para crear una subregión en la cuadrícula con un estado específico
void crear_grilla(int N, Estado id_area, int inicio_fila, int inicio_columna, int filas, int columnas) {
    for (int i = inicio_fila; i < inicio_fila + filas && i < N; i++) {
        for (int j = inicio_columna; j < inicio_columna + columnas && j < N; j++) {
            grid[i][j].estado = id_area;
        }
    }
}

// Función para mostrar la cuadrícula
void mostrar_grid(int N) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            switch(grid[i][j].estado) {
                case V: printf("  "); break;  // Representación de espacios vacíos
                case S: printf("S "); break;
                case E: printf("E "); break;
                case I: printf("I "); break;
                case R: printf("R "); break;
            }
        }
        printf("\n");
    }
}
// Función para contar vecinos infectados alrededor de una célula
int contar_infectados(int N, int x, int y) {
    int infectados = 0;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            if (i == 0 && j == 0) continue; // No contar la célula actual
            int nx = (x + i + N) % N;  // Asegurarse de que no salimos del rango
            int ny = (y + j + N) % N;
            if (grid[nx][ny].estado == I) {
                infectados++;
            }
        }
    }
    return infectados;
}

// Función para actualizar el estado de una célula
Estado actualizar_estado(int N, int x, int y) {
    Celula *c = &grid[x][y];
    int infectados_alrededor = contar_infectados(N, x, y);
    
    switch(c->estado) {
        case V:
            return V; // Las celdas vacías no cambian
        case S:
            // Si hay vecinos infectados, mayor probabilidad de exposición
            if (infectados_alrededor > 0) {
                float prob_exposicion = c->prob_exposicion * infectados_alrededor;
                if ((rand() / (float)RAND_MAX) < prob_exposicion) {
                    return E;  // Cambia a expuesto
                }
            }
            break;
        case E:
            // Si está expuesto, puede infectarse
            if ((rand() / (float)RAND_MAX) < c->prob_infeccion) {
                return I;  // Cambia a infectado
            }
            break;
        case I:
            // Si está infectado, puede recuperarse o morir
            if ((rand() / (float)RAND_MAX) < c->prob_recuperacion) {
                return R;  // Cambia a recuperado
            } else if ((rand() / (float)RAND_MAX) < c->prob_mortalidad) {
                return S;  // Muere y vuelve a ser susceptible
            }
            break;
        case R:
            // Los recuperados pueden perder inmunidad y volver a ser susceptibles
            if ((rand() / (float)RAND_MAX) < c->prob_perdida_inmunidad) {
                return S;  // Pierde inmunidad y vuelve a ser susceptible
            }
            break;
    }
    return c->estado;
}

// Función para simular un paso de la epidemia
void simular_paso(int N) {
    Celula **nuevo_grid = (Celula**)malloc(N * sizeof(Celula*));
    for (int i = 0; i < N; i++) {
        nuevo_grid[i] = (Celula*)malloc(N * sizeof(Celula));
    }

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            nuevo_grid[i][j].estado = actualizar_estado(N, i, j);
        }
    }

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            grid[i][j].estado = nuevo_grid[i][j].estado;
        }
    }

    for (int i = 0; i < N; i++) {
        free(nuevo_grid[i]);
    }
    free(nuevo_grid);
}

int main(int argc, char **argv)
{
    grid = (Celula**)malloc(N * sizeof(Celula*));
        for (int i = 0; i < N; i++) {
            grid[i] = (Celula*)malloc(N * sizeof(Celula));
        }
    yyparse();
    return 0;
}
