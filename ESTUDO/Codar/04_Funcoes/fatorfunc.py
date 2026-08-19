def fator(nf, show=False):
    c = nf-1
    fat = nf

    while c>=1:
        nf = fat
        fat *= c
        if show == True:
            print (f'{nf}x{c}={fat}')
        c -= 1
    print (fat)

num = int(input('NUMERO PARA FAZER O FATORIAL: '))
re = (input('QUER VER O PROCESSO? [S/N]: '))

if re.upper() != 'S':
    re = False
else:
    re = True
fator(num, re)