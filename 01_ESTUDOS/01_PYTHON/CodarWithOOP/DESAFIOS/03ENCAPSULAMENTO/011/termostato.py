

class Termostato:
    #min16 max30 inicio24 intervalo0.5
    def __init__(self, temperatura = 24):
        self.__temperatura = temperatura
    @property
    def mudatemp(self):
        return self.__temperatura
    
    @mudatemp.setter
    def mudartemp (self, valor):
        try:
            if valor%0.5 != 0:
                raise ValueError
            elif 16 <= valor <= 30:
                self.__temperatura = valor
            elif valor<16:
                self.__temperatura = 16
            else:
                self.__temperatura = 30
        except:
            print ('DIGITE UM VALOR CORRETO')