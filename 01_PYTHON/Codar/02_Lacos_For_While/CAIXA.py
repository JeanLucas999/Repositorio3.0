ac = 0
val = float(input('DIGITE QUANTO VOCE QUER SACAR: '))
dif = val
n50 = n20 = n10 = n1 = 0

while dif!=0:
    if dif>=50:
        dif -= 50
        n50 += 1
    if dif>=20 and dif<50:
        dif -= 20
        n20 += 1
    if dif>=10 and dif<20:
        dif -= 10
        n10 += 1
    if dif>=1 and dif<10:
        dif -= 1
        1 += 1
        break

print (f'VOCE RECEBEU {n50} NOTAS DE 50')
print (f'{n20} NOTAS DE 20')
print (f'{n10} NOTAS DE 10')
print (f'E {n1} MOEDAS DE 1')