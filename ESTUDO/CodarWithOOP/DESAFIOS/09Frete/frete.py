from abc import ABC, abstractmethod

class Transporte(ABC):
    def __init__(self, distancia = 0):
        self.distancia = distancia
        self.valor = 0

    @abstractmethod

    def calcFrete(self):
        pass

class Moto(Transporte):
    def __init__(self, distancia):
        super().__init__(distancia)
        self.fator = 0.5
    def calcFrete(self):
        self.valor = self.fator*self.distancia
        return self.valor

class Caminhao(Transporte):
    def __init__(self, distancia):
        super().__init__(distancia)
        self.fator = 1.2
    def calcFrete(self):
        if self.distancia<50:
            print('Distancia muito pequena para transporte de caminhao')
        else:
            self.valor = self.fator*self.distancia
            return self.valor

class Drone(Transporte):
    def __init__(self, distancia):
        super().__init__(distancia)
        self.fator = 9.0
    def calcFrete(self):
        if self.distancia>10:
            print ('Drone nao consegue andar tanto')
        else:
            self.valor = self.fator*self.distancia
            return self.valor

p1 = Caminhao(80)
p1.calcFrete()
print (f'A entrega de {type(p1).__name__} custara R${p1.calcFrete():.2f}')