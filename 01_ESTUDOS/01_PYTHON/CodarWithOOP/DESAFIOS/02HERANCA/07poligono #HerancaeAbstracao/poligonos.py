from abc import ABC, abstractmethod
from rich import print, inspect

class Poligono(ABC):
    def __init__(self, qntLados = 0):
        self.qntLados = qntLados

    @abstractmethod
    def perimetro(self):
        pass

    def area(self):
        pass

class Quadrado(Poligono):
    def __init__(self, lado, qntLados = 0):
        super().__init__(qntLados)
        self.qntLados = 4
        self.lado = lado

    def perimetro(self):
        self.perimetro = self.lado*self.qntLados
        return self.perimetro
    
    def area(self):
        self.area = self.lado*self.lado
        return self.area

    
class Redondo(Poligono):
    def __init__(self, raio, qntLados = 0):
        super().__init__(qntLados)
        self.qntLados = 0
        self.raio = raio

    def perimetro(self):
        self.perimetro = 3.14*self.raio*2
        return self.perimetro
    
    def area(self):
        self.area = 3.14*self.raio**2
        return self.area


p1 = Quadrado(4)
inspect(p1, methods=True)
p1.perimetro()
p1.area()
inspect(p1)
p2 = Redondo(20)
p2.perimetro()
p2.area()
inspect(p2)