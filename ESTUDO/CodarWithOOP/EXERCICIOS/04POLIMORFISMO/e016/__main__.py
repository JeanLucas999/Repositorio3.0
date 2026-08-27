from classes import *

def main():
    a = Numero(200)
    b = Texto('Gafanhoto')
    c = Lista([1, 2, 3])
    d = Papel()
    e = Casa()

    for i in (a, b, c, d, e):
        tenteDobra(i)
        print(i)


if __name__ == '__main__':
    main()