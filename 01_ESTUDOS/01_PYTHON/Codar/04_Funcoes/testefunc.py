def soma(n1, n2):
    so = n1 + n2
    print (so)

soma(4, 5)

soma(8, 9)

soma(2, 1)

soma(n2=2, n1=6)

def cont(*n):
    print (f'FORAM DIGITADOS {n}')

cont(1, 2, 3, 4)


def  dob(lst):
    pos = 0
    while pos < len(lst):
        lst[pos] *= 2
        pos += 1
    print (lst)

lista = [1, 2, 3, 4]
dob(lista)