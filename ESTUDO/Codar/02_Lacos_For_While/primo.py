num = int(input('DIGITE UM NUMERO PARA SABER SE EH PRIMO: '))
cont = 0
for c in range (1, num+1):
    if num%c==0:
        cont += 1
if cont<=2:
    print ('Esse numero eh um numero primo')
else:
    print ('Esse numero nao eh primo')