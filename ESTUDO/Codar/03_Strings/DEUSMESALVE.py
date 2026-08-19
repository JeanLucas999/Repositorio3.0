frase = (input('DIGITE UMA FRASE PARA SABER SE EH UM PALINDROMO: '))
fn = frase.replace(' ', '')
l = len(fn)
diguais = 0
ls = l-1
for c in range (0, l//2):
        if fn[c]==fn[ls]:
            diguais += 1
        else:
            print ('Nao eh um palindromo')
            break
        ls -= 1
        if diguais == l//2:
            print ('Eh um palindromo')
            break