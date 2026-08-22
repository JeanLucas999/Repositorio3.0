from banco import Conta


def main():
    c1 = Conta('Jean', 200, 111)
    c1.depositar(-500)
    
    c1.saque(100)
    print(c1)


if __name__ == '__main__':
    main()