n = int(input('DIGITE QUANTOS NUMEROS DE FIBONACCI QUER VER: '))
ta = 0
pt = 1
temp = 0
c = 0
while c<n:
    print (f'{ta}, ', end = '')
    temp = pt
    pt += ta
    ta = temp
    c += 1