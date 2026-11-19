def podevotar():
    from datetime import date
    
    hoje = date.today().year
    idade = hoje-nasc

    if idade < 16:
        return f'Com {idade} anos: voce nao pode votar'
    elif idade < 18:
        return f'Com {idade} anos: voce pode votar'
    else:
        return f'Com {idade} anos: voce DEVE votar'

nasc = int(input('DIGITE SEU ANO DE NASCIMENTO: '))
print (podevotar())