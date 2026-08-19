import tkinter as tk

class Task:
    def __init__(self):
        self.pronto = False
        self.color = ''
    def prontidao(self):
        if self.pronto == True:
            self.color = "#A9FFA6"
        else:
            self.color = "#FF7B7B"

def marcarpronto(indice):
    print (tarefas)
    print (indice)
    if tarefas[indice]['OBJETO'].pronto == False:
        tarefas[indice]['OBJETO'].pronto = True
    else:
        tarefas[indice]['OBJETO'].pronto = False
    tarefas[indice]['OBJETO'].prontidao()
    tarefanatela.config(bg=tarefas[indice]['COR'])




#------------------------------------------------
def addtxt():
    global txt
    txt = caixadetxt.get()
    tudo(txt)

def tudo(txtrecebido):
    global tarefanatela, linhaatual, taskcolor
    atualtask = {}
    taskcolor = Task()
    taskcolor.prontidao()

    atualtask['NOME'] = txtrecebido
    atualtask['COR'] = taskcolor.color
    atualtask['OBJETO'] = taskcolor
    tarefas.append(atualtask.copy())
    print(tarefas)

    tarefanatela = tk.Label(text=tarefas[linhaatual]['NOME'], bg=tarefas[linhaatual]['COR'], font=fonte, width=78, anchor='w', relief='groove')
    tarefanatela.grid(column=1, row=linhaatual+1, padx=(10, 0)) 
    checkbox.append(tk.Button(menu, text='/', width=3, height=1, command= lambda n=linhaatual: marcarpronto(n)))
    checkbox[linhaatual].grid(column=0, row=linhaatual+1, padx=(5, 0), pady=(3,0))
    tarefanatela.config(bg=tarefas[linhaatual]['COR'])
    linhaatual += 1
#------------------------------------------------


#ESTILOS
fonte = ('Bahnschrift SemiBold Condensed', 16)

tarefas = []
checkbox = []
linhaatual = 0
menu = tk.Tk()
menu.title('To Do List')
menu.geometry('1000x800')

caixadetxt = tk.Entry(menu, width=70, font=fonte, justify='center')
caixadetxt.grid(column= 1, row=0, padx=(10, 0))
add = tk.Button(menu, text='+', command=addtxt, font=(12), width=2)
add.grid(column= 0, row=0, padx=(5, 0))

tk.mainloop()