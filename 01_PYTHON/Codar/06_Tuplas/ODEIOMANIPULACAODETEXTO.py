tup =('CURSO', 'VIDEO', 'LABAXAURIAS')
c = 0
for c in tup:
    print (f'\nEM {c} temos: ', end ='')
    for letra in c:
        if letra.upper() in ('AEIOU'):
                print (letra, end =', ')