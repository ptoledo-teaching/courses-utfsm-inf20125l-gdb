# GDB: Depuración interactiva

## Introducción

En PF1 y PF2 se utilizaron mensajes para observar el estado interno de un programa. Este laboratorio presenta una estrategia diferente: observar la ejecución desde fuera del programa mediante GDB. Esto permite detenerse en puntos específicos, avanzar línea por línea, inspeccionar variables y revisar las llamadas activas sin agregar nuevos `printf` al código.

La actividad comienza con una introducción a la compilación con y sin símbolos de depuración. Luego se utiliza GDB para analizar progresivamente la ejecución de un programa.

### Prerrequisitos

- Haber completado PF1 y PF2
- Saber trabajar con archivos y directorios desde la terminal
- Saber editar un archivo con Vim
- Saber compilar un programa en C con GCC
- Tener disponibles `gcc`, `gdb`, `file`, `wget` y `tar`

### Objetivo general

- Utilizar GDB para detener, avanzar e inspeccionar la ejecución de un programa compilado con símbolos de depuración

### Objetivos específicos

- Comparar ejecutables compilados con y sin símbolos de depuración
- Iniciar y finalizar una sesión de GDB
- Crear y administrar breakpoints por función y por línea
- Iniciar, detener y avanzar la ejecución mediante `run`, `start`, `next`, `step`, `continue` y `finish`
- Inspeccionar expresiones, argumentos y variables locales
- Examinar las llamadas activas y seleccionar una de ellas mediante `frame`
- Observar expresiones automáticamente y modificar temporalmente una variable
- Verificar fuera de GDB el resultado obtenido durante la depuración

### Estructura inicial

```text
workspace/
├── code/
│   └── symbols.c
├── scripts/
│   └── check.sh
└── password.txt
```

El programa `symbols.c` permite comparar la información disponible con y sin símbolos de depuración. El archivo `password.txt` se utilizará durante todo el laboratorio para registrar la clave descubierta. El ejecutable principal y su código fuente se descargarán durante la actividad.

El script `check.sh` permite revisar qué actividades están completas y cuáles permanecen pendientes.

## Contexto

Durante una inspección de rutina a bordo de un crucero imperial, un cadete de la Academia Imperial de Coruscant encontró un contenedor de suministros que había sido saboteado por la Alianza Rebelde. En su interior se ocultaba un detonador térmico conectado al sistema de energía de la nave.

El equipo de seguridad determinó que el artefacto está protegido por una clave de cuatro números enteros que se validan en orden. Cada número correcto permite avanzar al mecanismo siguiente, mientras que un valor incorrecto provoca la detonación inmediata. Con la cuenta regresiva en curso, el cadete deberá reconstruir la clave completa y desactivar el artefacto antes de que comprometa el crucero.

## Actividad

### 1. Primeros pasos con GDB

Esta primera actividad se desarrollará de manera guiada durante la clase.

#### 1.1. Compilar las dos versiones

Ingresar a `workspace` y permanecer en este directorio durante todo el laboratorio. Los archivos ubicados dentro de `code` se utilizarán indicando su ruta desde `workspace`, sin ingresar a ese directorio.

Revisar `code/symbols.c`. El programa contiene intencionalmente una división por cero para observar cómo GDB presenta un error durante la ejecución. Este archivo no se debe corregir.

Compilar una primera versión con `-Wall`, `-Wextra`, `-Werror`, `-std=c11` y `-O0`. El ejecutable debe llamarse `symbols` y quedar dentro de `code`.

Compilar una segunda versión con las mismas opciones y agregar `-g`. Este ejecutable debe llamarse `symbols_g` y quedar en el mismo directorio.

La opción `-O0` desactiva las optimizaciones y facilita el seguimiento del código línea por línea. La opción `-g` incorpora la información que permite relacionar el ejecutable con el código fuente, sus funciones y sus variables.

> Las optimizaciones son transformaciones que el compilador realiza al generar el ejecutable para que el programa, por ejemplo, se ejecute más rápido o utilice menos espacio. Estas transformaciones pueden reorganizar o eliminar instrucciones y variables, lo que dificulta relacionar la ejecución con cada línea del código fuente.

#### 1.2. Examinar la versión sin símbolos

Abrir `code/symbols` con GDB y ejecutar el programa:

```text
gdb ./code/symbols
(gdb) run
```

> El comando `gdb ./code/symbols` inicia GDB y carga el programa `./code/symbols`, pero todavía no lo ejecuta. La ejecución comienza al ingresar `run` dentro de GDB.

Cuando la ejecución se detenga, utilizar `backtrace` para revisar las llamadas activas y `list` para intentar mostrar el código asociado. Observar qué información se encuentra disponible y cerrar la sesión con `quit`.

#### 1.3. Examinar la versión con símbolos

Abrir `code/symbols_g` con GDB y repetir la ejecución. Utilizar los siguientes comandos para examinar el estado del programa. Ejecutarlos uno por uno y observar la información que muestra la consola:

```text
gdb ./code/symbols_g
(gdb) run
(gdb) backtrace
(gdb) list
(gdb) frame 0
(gdb) info args
(gdb) frame 1
(gdb) info args
(gdb) info locals
```

Comparar la información obtenida con la sesión anterior e identificar dónde se originó el divisor igual a cero.

#### 1.4. Detener y avanzar la ejecución

Cerrar la sesión anterior y abrir nuevamente `code/symbols_g` desde `workspace`. Antes de ejecutar el programa, crear un breakpoint en la función `preparar`:

```text
gdb ./code/symbols_g
(gdb) break preparar
(gdb) run
```

Un breakpoint indica un punto donde GDB debe detener temporalmente la ejecución. En este caso, `run` inicia el programa y lo detiene al ingresar a `preparar`, antes de que la función comience sus instrucciones.

Ejecutar los siguientes comandos uno por uno y observar cómo cambia la línea seleccionada:

```text
(gdb) info breakpoints
(gdb) list
(gdb) next
(gdb) print divisor
(gdb) step
(gdb) info args
(gdb) continue
```

El comando `next` ejecuta la línea seleccionada sin ingresar a las funciones llamadas desde ella. El comando `step` también avanza una línea, pero ingresa a la función que se llama. Finalmente, `continue` reanuda la ejecución hasta alcanzar otro breakpoint, encontrar un error o terminar el programa.

GDB permite abreviar muchos comandos. Durante el laboratorio se pueden utilizar indistintamente las siguientes formas:

| Comando | Forma abreviada | Acción |
| --- | --- | --- |
| `run` | `r` | Inicia la ejecución desde el comienzo |
| `start` | — | Inicia la ejecución y se detiene al ingresar a `main` |
| `break` | `b` | Crea un breakpoint |
| `info breakpoints` | `i b` | Muestra los breakpoints configurados |
| `continue` | `c` | Reanuda la ejecución |
| `next` | `n` | Avanza sin ingresar a una función |
| `step` | `s` | Avanza ingresando a una función |
| `backtrace` | `bt` | Muestra las llamadas activas |
| `frame` | `f` | Selecciona una llamada activa |
| `list` | `l` | Muestra el código fuente cercano |
| `print` | `p` | Muestra el valor de una expresión |
| `quit` | `q` | Cierra GDB |

#### 1.5. Separar los símbolos del código fuente

Cerrar GDB, cambiar temporalmente el nombre de `code/symbols.c` y volver a abrir `code/symbols_g`. Ejecutar nuevamente el programa y probar `backtrace` y `list`.

Los símbolos continúan entregando nombres de funciones y números de línea, pero GDB no puede mostrar el contenido de esas líneas si no encuentra el archivo fuente. Antes de continuar, cerrar GDB y restaurar el nombre `code/symbols.c`.

### 2. Preparar el detonador térmico

#### 2.1. Descargar el archivo personalizado

Cada estudiante debe utilizar su rol como nombre de archivo. El rol se escribe con nueve dígitos, guion y dígito verificador (letra `K` mayúscula), por ejemplo `123456789-K`.

Estando en `workspace`, descargar el archivo correspondiente:

```text
wget https://ptoledo.org/courses/utfsm/inf20125l/20262/gdb/<ROL>.tar.gz
```

Reemplazar `<ROL>` por el identificador propio y expandir el archivo descargado dentro de `workspace`:

```text
tar -xzf <ROL>.tar.gz
```

La estructura de `code` quedará de la siguiente manera:

```text
code/
├── symbols
├── symbols.c
├── symbols_g
├── thermal_detonator
└── thermal_detonator.c
```

> Al expandir el archivo, no se reemplaza la carpeta `code` existente. Se agregan `thermal_detonator` y `thermal_detonator.c`, mientras que los archivos utilizados en la primera actividad se conservan.

El ejecutable ya contiene símbolos de depuración y no se debe recompilar. El código fuente está disponible para poder inspeccionar la ejecución.

#### 2.2. Preparar la primera clave

Desde `workspace`, revisar `password.txt`. El archivo debe contener cuatro números, uno por línea. Para el primer intento se utilizarán cuatro ceros:

```text
0
0
0
0
```

Abrir el detonador con GDB y ejecutarlo usando ese archivo como entrada:

```text
gdb ./code/thermal_detonator
(gdb) run < password.txt
```

El operador `<` se utiliza de la misma forma que en la terminal: entrega el contenido de `password.txt` a la entrada estándar (`stdin`) del programa ejecutado. En este caso, el detonador lee los cuatro valores desde el archivo en lugar de solicitarlos manualmente.

El detonador debe terminar con `BOOM!`. Esto corresponde al comportamiento esperado mientras la clave sea incorrecta.

#### 2.3. Reconocer el flujo inicial

El comando `start` comienza una nueva ejecución y se detiene temporalmente al ingresar a `main`:

```text
(gdb) start < password.txt
```

Desde ese punto, utilizar `next` y `step` para reconocer cuándo se inicializa el programa, cuándo se lee cada valor y cuándo comienza su validación. No es necesario recorrer por completo las cuatro fases en esta exploración.

### 3. Descubrir el primer número

#### 3.1. Detenerse en la primera validación

Crear un breakpoint al ingresar a `token_1_validate` y comenzar nuevamente la ejecución con `password.txt`.

El comando `step` permite entrar a la función llamada por la línea actual, mientras que `next` ejecuta esa línea sin ingresar a las funciones llamadas desde ella. Utilizar ambos comandos para ingresar a `token_1_calculate` y observar cómo cambia su variable local.

#### 3.2. Inspeccionar el valor calculado

Utilizar `print` para observar la variable local durante el cálculo. Luego ejecutar `finish` para regresar a `token_1_validate` y `next` para completar la asignación. Inspeccionar entonces la variable que contiene el resultado.

Contrastar el valor calculado con el primer número leído desde `password.txt`. Actualizar solamente la primera línea del archivo y comprobar que el detonador alcance la segunda fase antes de terminar.

### 4. Descubrir el segundo número

#### 4.1. Administrar los breakpoints

Utilizar `info breakpoints` para revisar los breakpoints configurados. Practicar `disable`, `enable` y `delete` sobre los breakpoints que ya no se necesiten.

Crear un breakpoint al ingresar a `token_2_validate`. Utilizar `list token_2_calculate` para identificar una línea dentro del cálculo y agregar también un breakpoint con el formato:

```text
(gdb) break thermal_detonator.c:<LINEA>
```

Ejecutar el programa con el primer número correcto y comparar el comportamiento de ambos breakpoints.

#### 4.2. Inspeccionar argumentos y variables

Avanzar por `token_2_calculate` utilizando `step` y `next`. Inspeccionar el valor ingresado anteriormente, los argumentos disponibles y las variables locales que intervienen en el cálculo.

Una vez identificado el segundo número, actualizar la segunda línea de `password.txt` y comprobar que la ejecución alcance la tercera fase.

### 5. Descubrir el tercer número

#### 5.1. Observar una llamada recursiva

Crear breakpoints en `token_3_validate` y `token_3_calculate`. Ejecutar el detonador con los dos primeros números correctos y permitir que la función de cálculo se invoque varias veces.

Utilizar `backtrace` para observar las llamadas activas. Cada llamada activa se muestra en GDB como un `frame`. La función recursiva aparecerá varias veces y cada llamada tendrá su propio valor para el parámetro `n`.

#### 5.2. Examinar las llamadas activas

Utilizar `frame <N>` para seleccionar distintas llamadas e inspeccionar sus argumentos y variables locales. Luego regresar a la llamada correspondiente a `token_3_validate` y determinar el resultado completo del cálculo.

El número asignado a cada `frame` puede variar según el punto donde se detuvo la ejecución. Se debe identificar la llamada por el nombre de su función y no asumir un número fijo.

Actualizar la tercera línea de `password.txt` y comprobar que el detonador alcance la cuarta fase.

### 6. Descubrir el cuarto número

#### 6.1. Observar expresiones automáticamente

Crear un breakpoint en `token_4_validate` y ejecutar el programa con los primeros tres números correctos. Utilizar `display` para observar automáticamente los cuatro valores de entrada cada vez que GDB detenga la ejecución.

Ingresar a `token_4_calculate`, avanzar hasta completar el cálculo y utilizar `finish` para regresar a `token_4_validate`. Ejecutar `next` para completar la asignación e inspeccionar la variable local `token` mediante `print` e `info locals` para confirmar el valor obtenido.

#### 6.2. Comprobar la hipótesis dentro de GDB

Antes de reiniciar el programa, utilizar `set var input_4 = token` para reemplazar temporalmente `input_4` por el valor calculado. Continuar la ejecución y comprobar que el detonador se desactive.

Esta modificación existe solamente durante la sesión de depuración. Registrar el cuarto número en la última línea de `password.txt` para conservar la clave completa.

### 7. Verificación final

#### 7.1. Probar la clave fuera de GDB

Cerrar GDB y ejecutar `code/thermal_detonator` desde la terminal utilizando `password.txt` como entrada. La última línea de `stdout` debe ser:

```text
Thermal detonator disabled
```

La ejecución debe terminar correctamente y `stderr` no debe contener mensajes.

#### 7.2. Habilitar el script

Agregar permiso de ejecución para el propietario de `scripts/check.sh`.

#### 7.3. Ejecutar la revisión

Ejecutar `scripts/check.sh` desde `workspace`. El script informa qué actividades están completas y cuáles permanecen pendientes.
