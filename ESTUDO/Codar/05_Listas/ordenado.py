r = 'S'
c = 0
lis = []
while r == 'S':
    sla = (int(input('DIGITE UM NUMERO PARA COLOCAR NA LISTA: ')))
    if sla not in lis:
        lis.append(sla)
    c += 1
    r = input('QUER CONTINUAR? S/N: ')
print (lis.sort)