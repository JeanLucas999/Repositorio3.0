from avaliacao import Avaliacao
from rich import print, inspect

def main():
    av1 = Avaliacao('Pedro', 'Mat')
    av1.set_nota(5)
    inspect (av1, private=True)
    print (av1.get_nota())
    pass

if __name__ == '__main__':
    main()