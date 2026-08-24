from abc import ABC, abstractmethod

class Pessoa:
    def __init__(self, nome, nascimento):
        self._nome = nome
        self._nascimento = nascimento
    @property

    def nascimento(self):
        return self._nascimento

    @nascimento.setter

    def nascimento(self, ano):
        if 1930 <= ano <= 2008:
            self._nascimento = ano
            self.idade = 2026-self._nascimento
        else:
            print ('Digite um ano valido')

class Aluno(Pessoa):
    def __init__(self, nome, nascimento, curso):
        super().__init__(nome, nascimento)
        self.cursosOficiais = ['ADS', 'MED', 'ENG', 'ARQ']
        try:
            if curso in self.cursosOficiais:
                self._curso = curso
            else:
                raise NameError
        except:
            print ('Curso inexistente!!!, tente addCurso')

    @property

    def curso(self):
        return self._curso

    @curso.setter

    def curso(self, curso):
        try:
            if curso in self.cursosOficiais:
                self._curso = curso
            else:
                raise NameError
        except:
            print ('Curso inexistente!!!, tente addCurso')

    def add_curso(self, nome):
        if 3 <= len(nome) <= 5:
            self.cursosOficiais.append(nome)
