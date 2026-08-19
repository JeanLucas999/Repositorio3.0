def leiaint():
    while True:
        try:
            n = int(input('DIGITE UM NUMERO: '))
        except:
            print('ERRO!!!')
        else:
            return n

def leiafloat():
    try:
        n = float(input('DIGITE UM NUMERO: '))
    except:
        print('ERRO!!!')
    else:
        return n

print (f'{leiaint()} EH UM NUMERO INTEIRO')
print (f'{leiafloat()} EH UM NUMERO FLUTUANTE')