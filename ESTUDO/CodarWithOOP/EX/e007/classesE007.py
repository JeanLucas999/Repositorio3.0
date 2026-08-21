from rich import print, inspect
from abc import ABC, abstractmethod #Abstract Base Classes


class Pessoa(ABC):
    def __init__(self, nome = '', idade = 0):
        self.nome = nome
        self. idade = idade
    def aniversario(self):
        self.idade += 1

    @abstractmethod
    def estudar(self):
        pass

class Aluno(Pessoa):
    def __init__(self, nome, idade, curso, turma):
        super().__init__(nome, idade)
        self.curso = curso
        self.turma = turma

    def matricula(self):
        pass

    def estudar(self):
        pass

class Professor(Pessoa):
    def __init__(self, nome, idade, especialidade, nivel):
        super().__init__(nome, idade)
        self.especialidade = especialidade
        self.nivel = nivel 

    def aula(self):
        pass

    def estudar(self):
        pass


class Funcionario(Pessoa):
    def __init__(self, nome, idade, cargo, setor):
        super().__init__(nome, idade)
        self.cargo = cargo
        self.setor = setor

    def ponto(self):
        pass

    def estudar(self):
        pass