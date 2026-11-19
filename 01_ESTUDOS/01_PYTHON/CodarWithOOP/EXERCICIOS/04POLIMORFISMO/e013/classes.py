from functools import singledispatchmethod


class Analisador:

    @singledispatchmethod
    def analisar(self, valor):
        print (f'Nao foi possivel analisar o valor {valor}')

    @analisar.register
    def _(self, valor: int):
        #if valor == int
        print (f'{valor} e inteiro')

    @analisar.register
    def _(self, valor: str):
        print (f'{valor} e str')

    @analisar.register
    def _(self, valor: tuple|list|dict):
        print (f'{valor} e um valor composto')
