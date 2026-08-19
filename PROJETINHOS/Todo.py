import tkinter as tk

class lista():
    def __init__(self):
        self.check  = False
        self.tarefa = ''
        self.botao = ''
    def taskcreate(self, texto):
        print ('TASKCREATE')
        #Nome aletorio, aqui vou organizar tudo em um dicionario
        global linha

        print (linha)

        self.botao = tk.Label(text=texto, width=75, font=fonte, relief='groove', anchor='w')
        self.check = False
        objetos.append(novinho)
        objetos[0].botao.grid(padx=(5,0), row=linha, column=1)

        linha += 1


    def checarbotao(self):
        a

def addtxt():
    #PUXA O DIABO DO TEXTO E MANDA O OBJETO PRA CLASSE
    print("ADDTXT")
    global novinho
    txt = escrever.get()
    novinho = lista()
    novinho.taskcreate(txt)


def criarbotoes():
    print("CRIAR BOTAO")
    global escrever
    escrever = tk.Entry(menu, justify='center', width=75, font=fonte)
    escrever.grid(padx=(5, 0), row=0, column=1)
    add = tk.Button(menu, text='+', command= addtxt)
    add.grid(padx=(5, 0), row=0, column=0)


objetos = []
objeto = {}   
fonte = ('Segoe UI', 12)  
linha = 1

menu = tk.Tk()
menu.title('To-Do')
menu.geometry('800x600')
criarbotoes()

menu.mainloop()