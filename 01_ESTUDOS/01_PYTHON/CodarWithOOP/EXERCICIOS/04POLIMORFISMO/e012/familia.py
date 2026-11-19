class Mae:
    def __init__(self, nome:str = 'Mae'):
        self.nome = nome

    def fazerPudim(self):
        print (f'{self.nome} faz pudim com leite condensado e calda')

    def fritarCoxinha(self):
        print (f'{self.nome} frita coxinha no oleo de soja')

class Filho(Mae):
    def fritarCoxinha(self):
        print (f'Frita coxinha na air fryer')

class Filha(Mae):
    def fazerPudim(self):
        print (f'{self.nome} faz pudim gelado') 