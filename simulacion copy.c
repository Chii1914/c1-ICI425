#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>

// Estados posibles
typedef enum {V, S, E, I, R} Estado;

// Estructura para representar una célula
typedef struct {
    Estado estado;
    float prob_infeccion;
    float prob_exposicion;
    float prob_recuperacion;
    float prob_mortalidad;
    float prob_perdida_inmunidad;
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
    Automata ***matriz;  // Matriz bidimensional para facilitar el acceso
    int filas;
    int columnas;
} MatrizAutomatas;

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

// Función para dibujar la cuadrícula de un autómata en la ventana
void mostrar_grid(Automata *automata, SDL_Renderer *renderer, int offset_x, int offset_y, int cell_size) {
    for (int i = 0; i < automata->N; i++) {
        for (int j = 0; j < automata->N; j++) {
            SDL_Rect rect = { offset_x + j * cell_size, offset_y + i * cell_size, cell_size, cell_size };
            switch(automata->grid[i][j].estado) {
                case V: SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255); break;  // Blanco
                case S: SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255); break;      // Verde
                case E: SDL_SetRenderDrawColor(renderer, 255, 255, 0, 255); break;    // Amarillo
                case I: SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255); break;      // Rojo
                case R: SDL_SetRenderDrawColor(renderer, 0, 0, 255, 255); break;      // Azul
            }
            SDL_RenderFillRect(renderer, &rect);
            // Opcional: dibujar el borde de la célula
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);  // Negro
            SDL_RenderDrawRect(renderer, &rect);
        }
    }
}

// Función para dibujar un fondo para cada autómata (opcional)
void dibujar_fondo_automata(SDL_Renderer *renderer, int offset_x, int offset_y, int N, int cell_size, int alternar_color) {
    SDL_Rect rect = { offset_x, offset_y, N * cell_size, N * cell_size };
    if (alternar_color) {
        SDL_SetRenderDrawColor(renderer, 230, 230, 230, 255);  // Gris claro
    } else {
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);  // Blanco
    }
    SDL_RenderFillRect(renderer, &rect);
}

// Función para dibujar un borde grueso alrededor del autómata
void dibujar_borde_automata_grueso(SDL_Renderer *renderer, int offset_x, int offset_y, int N, int cell_size, int grosor) {
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // Negro
    for (int i = 0; i < grosor; i++) {
        SDL_Rect rect = { offset_x - i, offset_y - i, N * cell_size + 2 * i, N * cell_size + 2 * i };
        SDL_RenderDrawRect(renderer, &rect);
    }
}

// Función para dibujar texto (ID del autómata)
void dibujar_texto(SDL_Renderer *renderer, TTF_Font *font, int x, int y, const char *texto, SDL_Color color) {
    SDL_Surface *surface = TTF_RenderText_Solid(font, texto, color);
    SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_Rect dstrect = { x, y, surface->w, surface->h };
    SDL_RenderCopy(renderer, texture, NULL, &dstrect);
    SDL_FreeSurface(surface);
    SDL_DestroyTexture(texture);
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
    printf("Matriz de IDs de Autómatas:\n");
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
    free(matriz);
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

int main() {
    srand(time(NULL));

    // Inicializar SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        fprintf(stderr, "Error al inicializar SDL: %s\n", SDL_GetError());
        return 1;
    }

    // Inicializar SDL_ttf
    if (TTF_Init() < 0) {
        fprintf(stderr, "Error al inicializar SDL_ttf: %s\n", TTF_GetError());
        SDL_Quit();
        return 1;
    }

    int cell_size = 20;  // Tamaño de cada célula en píxeles
    int N = 20;          // Tamaño del autómata (20x20 células)
    int filas = 2, columnas = 2;  // Tamaño de la matriz de autómatas

    int window_width = columnas * N * cell_size;
    int window_height = filas * N * cell_size;

    SDL_Window *window = SDL_CreateWindow("Simulación de Autómata Celular",
                                          SDL_WINDOWPOS_CENTERED,
                                          SDL_WINDOWPOS_CENTERED,
                                          window_width, window_height,
                                          SDL_WINDOW_SHOWN);
    if (!window) {
        fprintf(stderr, "Error al crear la ventana: %s\n", SDL_GetError());
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        fprintf(stderr, "Error al crear el renderizador: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    // Cargar fuente para el texto
    TTF_Font *font = TTF_OpenFont("Arial.ttf", 16);
    if (!font) {
        fprintf(stderr, "Error al cargar la fuente: %s\n", TTF_GetError());
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    // Crear la matriz de autómatas
    MatrizAutomatas *matriz_automatas = crear_matriz_automatas(filas, columnas, N);

    // Establecer IDs para los autómatas
    establecer_id(matriz_automatas->matriz[0][0], 1);
    establecer_id(matriz_automatas->matriz[0][1], 2);
    establecer_id(matriz_automatas->matriz[1][0], 3);
    establecer_id(matriz_automatas->matriz[1][1], 4);

    // Agregar áreas en los autómatas
    agregar_area(matriz_automatas->matriz[0][0], S, 0, 0, N, N);  // Todo 'S' en autómata (0,0)
    agregar_area(matriz_automatas->matriz[0][1], I, 0, 0, N, N);  // Todo 'I' en autómata (0,1)
    agregar_area(matriz_automatas->matriz[1][0], S, 0, 0, N, N);  // Todo 'S' en autómata (1,0)
    agregar_area(matriz_automatas->matriz[1][1], I, 0, 0, N/2, N/2);  // 10x10 de 'I' en autómata (1,1)
    agregar_area(matriz_automatas->matriz[1][1], I, 1, 1, 1, 1);  // 10x10 de 'I' en autómata (1,1)

    // Mostrar la matriz de IDs de autómatas
    mostrar_matriz_ids(matriz_automatas);

    // Bucle de simulación
    SDL_Event event;
    int quit = 0;
    int tiempo_total = 100000000000;

    for (int t = 0; t < tiempo_total && !quit; t++) {
        // Manejo de eventos
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                quit = 1;
            }
        }

        // Avanzar la simulación
        avanzar_simulacion(matriz_automatas, 1);

        // Limpiar la pantalla
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        SDL_RenderClear(renderer);

        // Dibujar cada autómata
        for (int i = 0; i < matriz_automatas->filas; i++) {
            for (int j = 0; j < matriz_automatas->columnas; j++) {
                int offset_x = j * N * cell_size;
                int offset_y = i * N * cell_size;

                // Dibujar fondo alterno (opcional)
                int alternar_color = (i + j) % 2;
                dibujar_fondo_automata(renderer, offset_x, offset_y, N, cell_size, alternar_color);

                mostrar_grid(matriz_automatas->matriz[i][j], renderer, offset_x, offset_y, cell_size);

                // Dibujar un borde grueso alrededor del autómata
                int grosor_borde = 3;  // Grosor del borde en píxeles
                dibujar_borde_automata_grueso(renderer, offset_x, offset_y, N, cell_size, grosor_borde);

                // Dibujar el ID del autómata
                char texto_id[10];
                snprintf(texto_id, sizeof(texto_id), "ID: %d", matriz_automatas->matriz[i][j]->id);
                SDL_Color color_texto = {0, 0, 0};  // Negro
                dibujar_texto(renderer, font, offset_x + 5, offset_y + 5, texto_id, color_texto);
            }
        }

        // Actualizar la ventana
        SDL_RenderPresent(renderer);

        // Controlar la velocidad de la simulación
        SDL_Delay(100);  // 100 milisegundos por paso
    }

    // Mostrar los resultados después de la simulación
    printf("\nDespués de la simulación:\n");
    mostrar_matriz_automatas(matriz_automatas);

    // Limpiar y salir
    liberar_matriz_automatas(matriz_automatas);
    TTF_CloseFont(font);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    TTF_Quit();
    SDL_Quit();

    return 0;
}
