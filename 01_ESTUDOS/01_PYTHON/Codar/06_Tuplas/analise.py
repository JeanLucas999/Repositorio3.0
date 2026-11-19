bla = ((int(input('DIGITE O NUMERO:'))), (int(input('DIGITE O NUMERO:'))), (int(input('DIGITE O NUMERO:'))), (int(input('DIGITE O NUMERO:'))))
c = 0

print (bla.count(9))
print (bla.count(3))

for c in range(0,4):
    if bla[c]%2 == 0:
        if c<3:
            print (f'{bla[c]}', end=' e ')
        else:
            print (f'{bla[c]}', end=' ')
        c+1
print ('sao pares')