class Caneta:
    def __init__(self, cor = ''):
        self.cor = cor
        self.tampa = True
        self.linha = False

        if self.cor == 'vermelha':
            self.pintar = '\033[31m'
        if self.cor == 'azul':
            self.pintar = '\033[34m'
        if self.cor == 'verde':
            self.pintar = '\033[32m'

    def destampar(self):
        self.tampa = False

    def quebrarlinha(self, n = 1):
        self.linha = True
        for c in range (0, n):
            print ('')
            
    def escrever(self, texto = ''):
        if self.tampa == True:
            print ('CANETA TAMPADA!!!')
        else:
            print (f'{self.pintar}{texto}{terminar}', end= ' ')
        pass
        

terminar = '\33[m'

c1 = Caneta('vermelha')
c2 = Caneta('azul')
c3 = Caneta('verde')

c1.destampar()
c2.destampar()
c3.destampar()

c1.escrever('Ola Mundo')
c1.quebrarlinha(2)
c2.escrever('Legal,')
c3.escrever('eu sou um objeto')
