class Avaliacao:
    def __init__(self, nome, disciplina, nota = 0):
        self.nome = nome
        self.disciplina = disciplina
        self._nota = nota
    #CRIANDO ATRIBUTO VALIDAVEL
    
    @property
    def mudarnota(self): #getter
        return self._nota

    @mudarnota.setter
    def mudarnota (self, valor): #setter
        if 0 <= valor <= 10:
            self._nota = valor
        else:
            print('Nota invalida')