print ('ANALISADOR DE TRIANGULOS 2000')

l1 = float(input('Digite o primeiro lado: '))
l2 = float(input('Digite o segundo lado: '))
l3 = float(input('Digite o ultimo lado: '))
tri = True

if l1+l2>l3 and l2+l3>l1 and l1+l3>l2:
    tri = True
    print('\033[0;32mEssas medidas podem formar um triangulo\033[m')

    if l1==l2 and l2==l3:
        print('E esse triangulo eh EQUILATERO')

    elif (l1==l2 and l2!=l3) or (l2==l3 and l2!=l1):
        print('E esse triangulo eh ISOSCELES')

    elif l1!=l2 and l2!=l3:
        print('E esse triangulo eh ESCALENO')

else:
    print('\033[0;31mEssas medidas nao podem formar um triangulo')
    
