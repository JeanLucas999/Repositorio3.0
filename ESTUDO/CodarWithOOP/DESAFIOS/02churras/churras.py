class Churras:
    def __init__(self, quantidade = 0):
        self.qntd = quantidade
        self.kgs = quantidade/2
        self.preco = 25*self.kgs/self.qntd
    def tudo(self):
        print (f'Para as {self.qntd} pessoas sera necessario (O RIFLE) {self.kgs}kgs de LINGUICA')
        print (f'Com o kg a R$25.00, custara {self.preco:.2f} por pessoa')


pessoas = Churras(5)
pessoas.tudo()