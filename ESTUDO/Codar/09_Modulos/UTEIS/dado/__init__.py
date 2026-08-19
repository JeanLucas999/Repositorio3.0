def validei():
    while True:
        num = (input('DIGITE O VALOR: ')).strip()
        if num.isalpha() or num == '':
            print (f'ERRO!!! "{num}" NAO EH NUMERO, DIGITE UM')
        else:
            num = num.replace(',', '.')
            num = float(num)
            return num
