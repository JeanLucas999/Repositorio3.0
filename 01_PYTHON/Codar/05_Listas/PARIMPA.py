r = 'S'
lis = []
lisp = []
lisi = []
c = 0
while r == 'S' or  r == 's':
    sla = int(input('DIGITE UM NUMERO PARA COLOCAR NA LISTA'))
    lis.append(sla)
    if sla%2 == 0:
        lisp.append(sla)
    else:
        lisi.append(sla)
    r = input('QUER CONTINUAR? S/N: ')
lis.sort()
lisp.sort()
lisi.sort()

print (f'{lis} SAO TODOS NUMEROS DA LISTA')
print (f'{lisp} SAO OS PARES DA LISTA')
print (f'{lisi} SAO OS IMPARES DA LISTA')