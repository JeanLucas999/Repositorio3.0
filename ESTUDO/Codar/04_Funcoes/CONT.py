from time import sleep

def cont(a, b, c):
    i = a 
    print ('-'*35)
    
    if a<b:
        b += 1
        if c<0:
            c *= -1
    else:
        b -= 1
        if c>0:
            c *= -1

    for i in range(a, b, c):
        print(i, end=' ', flush=True)
        sleep(0.2)

print ('[1] PARA CONTAR DE 1 ATE 10\n'
'[2] PARA CONTAR DE 10 ATE 1\n'
'[OUTRO] PARA ESCOLHER SUA CONTAGEM')
print ('-'*35)
re = int(input('QUE CONTAGEM QUER FAZER? '))

if re == 1:
    cont(1, 10, 1)
elif re == 2:
    cont(10, 1, -1)
else:
    cont(int(input('CONTAR COMECANDO POR: ')), int(input('ATE: ')), int(input('DE QUANTO EM QUANTO: ')))