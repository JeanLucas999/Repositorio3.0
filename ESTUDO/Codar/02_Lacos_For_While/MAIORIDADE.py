from datetime import date
sm = 0
hoje = date.today().year
for c in range (0, 7):
    ano = int(input('Digite em que ano voce nasceu: '))
    if hoje-ano>=18:
        sm += 1
print (f'Dos sete {sm} sao de maior')
#print(c, end=' ')