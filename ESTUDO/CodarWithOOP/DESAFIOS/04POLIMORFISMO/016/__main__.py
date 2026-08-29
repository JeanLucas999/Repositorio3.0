from salariobonus import *
from rich import inspect


def main():
    a = Gerente('Jean', 2000)
    a.salario = 2100
    print(a)
    print(a.calcular_bonus())


if __name__ == '__main__':
    main()