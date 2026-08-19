lis = []
for c in range (1, 6):
    lis.append(int(input(f'\33[2;31mDIGITE O {c}o NUMERO DESSA LISTA: \33[m')))
    if c == 1:
        maior = lis[0]
        menor = lis[0]
    else:
        if maior<lis[c-1]:
            maior = lis[c-1]
        if menor>lis[c-1]:
            menor = lis[c-1]
print (f'VOCE DIGITOU OS VALORES: {lis}')
print (f'DENTRO DISSO, O MAIOR FOI: {maior} QUE ESTAVA NA POSICAO {lis.index(maior)+1}')
print (f'E O MENOR FOI: {menor} NA POSICAO {lis.index(menor)+1}')