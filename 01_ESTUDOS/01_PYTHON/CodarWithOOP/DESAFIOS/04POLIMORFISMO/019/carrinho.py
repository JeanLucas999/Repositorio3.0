from rich import inspect

class Produto:
    def __init__(self, nome:str, valor:int|float = 0):
        self.nome = nome
        self.valor = valor

    def __str__(self):
        return f'{self.nome} (R${self.valor:.2f})'


class Carrinho:
    def __init__(self):
        self.produtos = []

    @property
    def somatotal(self):
        self.__soma = 0
        for c in self.produtos:
            self.__soma += c.valor
        return self.__soma

    @somatotal.setter
    def somatotal(self):
        print ('Nao e possivel alteral o total!!!')

    def __iadd__(self, obj):
        if isinstance(obj, Produto):
            self.produtos.append(obj)
            self.somatotal
            return self
        else:
            self.produtos += obj.produtos
            self.somatotal
            return self

    def __str__(self):
        lista = '\n'.join(str(produto) for produto in self.produtos)
        return f'----------------------\n{lista}\n----------------------\nTOTAL DE: R${self.__soma:.2f}'

p1 = Produto('Mouse', 50)
p2 = Produto('Teclado', 100)
p3 = Produto('GPU', 2000)

c1 = Carrinho()
c2 = Carrinho()

c1 += p1
c1 += p2
c1 += p3

c2 += p1
c1 += c2


print (c1)
