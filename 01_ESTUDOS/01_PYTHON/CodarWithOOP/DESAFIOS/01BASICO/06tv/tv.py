class Controle():
    def __init__(self):
        self.volume = 1
        self.canal = 1
        self.on = False
        self.key = ''
        pass

    def comando(self):
        while self.key != '0':
            self.menu()
            self.key = input('< CH >  - VOL + | ')
            if self.key == '@':
                if self.on == False:
                    self.on = True
                else:
                    self.on = False
            if self.on == True:
                #VOLUME DIMINUIR OU AUMENTAR
                if self.key in ('+-'):
                    if self.key == '-':
                        if self.volume>1:
                            self.volume -= 1

                    else:
                        if self.volume<5:
                            self.volume += 1

                #CANAL DESCER OU SUBIR
                elif self.key in ('<>'):
                    if self.key == '<':
                        if self.canal == 1:
                            self.canal = 5
                        else:
                            self.canal -= 1

                    else:
                        if self.canal == 5:
                            self.canal = 1
                        else:
                            self.canal += 1
            if self.key == '0':
                break
            
            print ('\n')

    def menu(self):
        if self.on == False:
            print (' ------------------------')
            print (' ------TV DESLIGADA------')
            print (' ------------------------')
        else:
            print (' -----------TV-----------')

            #CANAIS
            for c in range(1, 6):
                if c == 1:
                    print ('CH', end= '  ')
                if c == self.canal:
                    if c != 5:
                        print (f'\033[31m{c}   \033[m', end=' ')
                elif c!= self.canal and c != 5:
                    print (f'{c}   ', end = ' ')
                if c == 5:
                    if c != self.canal:
                        print (f'{c}|')
                    else:
                        print (f'\033[31m{c}|\033[m')

            #VOLUMES
            for c in range(1, 6):
                if c == 1:
                    print ('VOL', end= ' ')
                if c == self.volume:
                    if c != 5:
                        print (f'\033[31m{c}   \033[m', end=' ')
                elif c!= self.volume and c != 5:
                    print (f'{c}   ', end = ' ')
                if c == 5:
                    if c != self.volume:
                        print (f'{c}|')
                    else:
                        print (f'\033[31m{c}|\033[m')

            print (' ------------------------')
        pass

controle = Controle()
controle.comando()