mat = [[0, 0, 0],
       [0, 0, 0],
       [0, 0, 0]]
par = 0
s3 = 0
maior = 0
for c in range(3):
    for p in range(3):
        n = int(input(f'DIGITE UM NUMERO PARA A POSICAO {c}, {p}: '))
        mat[c][p] = n

        if p == 2:
            s3 += n

        if n%2==0: 
             par += n

        if c == 1 and p == 0:
            maior = mat[c][p]
        elif c == 1:
             if mat[c][p]>maior:
                  maior = mat[c][p]
             

for c in range(3):
    print (mat[c])

print(f'O MAIOR NUMERO DA SEGUNDA LINHA EH: {maior}')
print(f'A SOMA DOS NUMEROS DA TERCEIRA COLUNA EH: {s3}')
print(f'A SOMA DOS PARES EH: {par}')