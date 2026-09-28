#include <stdio.h>

static int dividir(int total, int divisor)
{
    return total / divisor;
}

static int preparar(int base)
{
    int divisor = base - 4;

    return dividir(120, divisor);
}

int main(void)
{
    int base = 4;
    int resultado = preparar(base);

    printf("Resultado: %d\n", resultado);

    return 0;
}
