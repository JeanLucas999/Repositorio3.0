from diario import Diario
from rich import inspect

def main():
    diario = Diario('JeanLucas1@')
    diario.escrever('Ola mundo')
    diario.escrever('Soy lo mejor')
    inspect(diario, private=True, methods=True)
    diario.ler('JeanLucas1@')


if __name__ == '__main__':
    main()