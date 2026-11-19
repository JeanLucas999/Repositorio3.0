lis = []

for c in range(5):
    n = int(input(f'Digite o {c+1}º valor: '))
    lis.append(n)

    i = c
    while i > 0 and lis[i] < lis[i-1]:
        lis[i], lis[i-1] = lis[i-1], lis[i]
        i -= 1

print(lis)
