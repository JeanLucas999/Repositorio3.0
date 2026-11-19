class Retangulo:
    def __init__(self, base=1, altura=1):
        self._base = base
        self._altura = altura
        pass

    @property
    def base(self):
        return (self._base)

    @base.setter
    def base(self, valor):
        if valor > 0:
            self._base = valor
        else:
            print ('O valor deve ser maior que 0')

    @property
    def altura(self):
        return (self._altura)

    @altura.setter
    def altura(self, valor):
        if valor > 0:
            self._altura = valor
        else:
            print ('O valor deve ser maior que 0')

    @property
    def medidas(self):
        self.area = self._altura*self._base
        return (self.area, self._altura, self._base)
