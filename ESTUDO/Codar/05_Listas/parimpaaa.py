pi = [[], []]
n = 0

for c in range (7):
    n = int(input(f'DIGITE O {c+1}o NUMERO: '))
    if n%2 == 0:
        pi[0].append(n)
    else:
        pi[1].append(n)
print (f'{sorted(pi[0])} SAO OS PARES')
print (f'{sorted(pi[1])} SAO OS IMPARES')