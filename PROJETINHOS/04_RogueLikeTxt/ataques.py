#Ordem para o dicionario de cada ataque:
#TIPO
#NOME, DESCRICAO, MULTIPLICADOR DE DANO, CHANCE DE ACERTO, TAXA, DANO CRITICO, TIPO, EFEITO, CHANCEEFEITO, LISTA COM FRASES DE ATAQUE NORMAL, LISTA COM FRASES DE DANO CRITICO, LISTA DE ERROS
    #{'nome': 'Investida', 'dano': 1, 'chance': 95, 'taxa': 1, 'critico': 1, 'tipo': 'basico', 
     
    #'acerto': 
    #[

    #],

    #'critou':
    #[
    #    
    #],

    #'erro':
    #[

    #]
    #}

#Efeitos tem duracao por turnos e dano porcento

tiposAtuais = ['basico', 'humanoide', 'voador', 'devoto', 'animal', 'perverso', 'venenoso', 'inseto', 'sagrado', 'pesado', 'vampirismo']




listaEfeitos = {
    'veneno':
    {'nome': 'Veneno', 'duracao': 5, 'dano': 10}
}


listaAtaques =  {
    #BASICOS
    'investida':
    {'nome': 'Investida', 'desc': 'Investe contra o inimigo causando 1x seu ataque', 'dano': 1, 'chance': 95, 'taxa': 10, 'critico': 1.5, 'tipo': 'basico', 'efeito': 'sem',

    'acerto': 
    [
        'investiu contra o oponente dando uma cabeçada',
        'deu uma ombrada no oponente',
        'avançou feito um touro e acertou o oponente em cheio',
        'correu de cabeça baixa e levou o oponente junto'
    ],

    'critou':
    [
        'investiu dando uma puta cabeçada no oponente que até deixou ele tonto',
        'investiu dando uma ombrada que jogou o oponente para longe',
        'investiu com tanta velocidade que o oponente girou duas vezes antes de cair',
        'investiu tão forte que o oponente perguntou que dia era hoje'
    ],

    'erro':
    [
        'tentou investir, tropeçou e caiu no chão apenas perdendo aura',
        'foi dar uma ombrada no oponente, ele desviou e fez um sinal de "Não" com a cabeça',
        'investiu com tudo, o oponente deu um passo para o lado e o golpe acertou o vento',
        'correu para investir, não olhou o chão e deu de cara numa pedra'
    ]
    },

    #HUMANOIDES
    'tapa':
    {'nome': 'Tapa', 'desc': 'Dá um tapa no inimigo causando 1.2x seu ataque', 'dano': 1.2, 'chance': 80, 'taxa': 10, 'critico': 1.5, 'tipo': 'humanoide', 'efeito': 'sem',
    
    'acerto': 
    [
        'deu um tapa na cara do oponente',
        'deu um tapa na bunda do oponente',
        'deu um tapa tão estalado que ecoou pela arena inteira',
        'deu um tapa com as costas da mão, bem dramático'
    ],

    'critou':
    [
        'deu um TAPÃO na cara do oponente que até deixou ele tonto',
        'deu um baita dum tapa na bunda do oponente',
        'deu um tapão tão forte que o rosto do oponente ficou virado por alguns segundos',
        'deu um tapa que fez o oponente girar igual pião'
    ],

    'erro':
    [
        'foi dar um tapa na cara do oponente, o mesmo riu, quem usaria um tapa em uma luta?',
        'tentou dar um tapa na bunda do oponente, você realmente achou que funcionaria.',
        'foi dar um tapa, o oponente segurou a mão e ficou um silêncio constrangedor',
        'errou o tapa e acertou a própria perna, quem diria'
    ]
    },

    #VOADORES
    'rasante':
    {'nome': 'Rasante', 'desc': 'Sobe para voo e avança 0.9x do ataque', 'dano': 0.9, 'chance': 90, 'taxa': 20, 'critico': 1.8, 'tipo': 'voador', 'efeito': 'sem',
        
    'acerto': 
    [
        'subiu para o infinito e alem, desceu dando um chute no inimigo',
        'voou para tras pegando impulso e voltou dando um soco no oponente',
        'deu um rasante tão baixo que raspou o cabelo do oponente (e um pouco da cabeça junto)',
        'subiu, fez uma pose heroica e caiu com uma voadora no oponente'
    ],

    'critou':
    [
        'subiu até as estrelas e caiu dando um mortal duplo carpado bem na cabeça do oponente',
        'voou para tras como se fosse um estilingue e numa velocidade absurda bateu no inimigo',
        'desceu do céu como um meteoro e o oponente virou cratera',
        'veio de cima tão rápido que o som chegou depois do golpe'
    ],

    'erro':
    [
        'subiu para o infinito e alem(tentou), o oponente segurou seus pés e devolveu para o chão',
        'voou para tras. cansou.',
        'subiu, mirou e acertou uma árvore. A árvore não gostou',
        'tentou um rasante, esqueceu como se aterrissa e rolou pelo chão'
    ]
    },

    #DEVOTOS
    'cabecadaZen':
    {'nome': 'Cabeçada Zen', 'desc': 'Medita e dá uma cabeçada precisa, 1.3x seu ataque', 'dano': 1.3, 'chance': 50, 'taxa': 30, 'critico': 2.0, 'tipo': 'devoto', 'efeito': 'sem',

    'acerto':
    [
        'respirou fundo, abriu os olhos e acertou uma cabeçada perfeita',
        'encontrou a paz interior e a testa do oponente',
        'fechou os olhos, contou até três e acertou a cabeçada no ponto exato',
        'seguiu o fluxo do universo, que por acaso passava pela testa do oponente'
    ],

    'critou':
    [
        'atingiu a iluminação e a cabeça do oponente ao mesmo tempo',
        'a cabeçada ecoou pela montanha inteira',
        'a cabeçada foi tão pura que o oponente viu a luz no fim do túnel',
        'transcendeu o corpo e a testa, o oponente foi junto para outra dimensão'
    ],

    'erro':
    [
        'meditou tanto que o oponente foi lanchar e voltou',
        'ficou em paz consigo mesmo. O oponente não ficou em paz com ele.',
        'respirou fundo demais, começou a tossir e perdeu a concentração',
        'ficou tão concentrado que cabeceou o ar, e o universo estava ocupado demais para ajudar'
    ]
    },

    #ANIMAIS
    'mordida':
    {'nome': 'Mordida', 'desc': 'Morde o inimigo causando 1.3x seu ataque', 'dano': 1.3, 'chance': 75, 'taxa': 10, 'critico': 1.6, 'tipo': 'animal', 'efeito': 'sem',

    'acerto':
    [
        'mordeu a perna do oponente e não soltou por alguns segundos',
        'cravou os dentes no braço do oponente',
        'mordeu o oponente com tanta convicção que deixou a marca dos dentes',
        'agarrou o oponente com os dentes igual cachorro em osso'
    ],

    'critou':
    [
        'mordeu com tanta força que o oponente gritou igual criança',
        'arrancou um pedaço do oponente (não era pra ter feito isso)',
        'mordeu tão forte que o oponente prometeu tomar vacina antitetânica',
        'deu uma mordida tão violenta que dava pra ouvir o "nhac" de longe'
    ],

    'erro':
    [
        'tentou morder, mas mordeu a própria língua',
        'abriu a boca pra morder e o oponente colocou um pimentão ali dentro',
        'mordeu o oponente, mas era só a armadura. Dente dolorido',
        'foi morder e o oponente mordeu de volta. Ninguém esperava essa'
    ]
    },

    #PERVERSOS
    'golpeBaixo':
    {'nome': 'Golpe Baixo', 'desc': 'Ataque sujo, 1x seu ataque e alto crítico', 'dano': 1, 'chance': 80, 'taxa': 10, 'critico': 2.5, 'tipo': 'perverso', 'efeito': 'sem',

    'acerto':
    [
        'acertou um golpe baixo e fingiu que foi sem querer',
        'chutou onde não devia',
        'deu um golpe baixo e saiu assobiando como se nada tivesse acontecido',
        'deu um chute baixo e pediu desculpas sem a menor sinceridade'
    ],

    'critou':
    [
        'acertou o ponto mais sensível do oponente, que viu a vida passar diante dos olhos',
        'o golpe foi tão baixo que a torcida vaiou. Mas funcionou.',
        'o golpe foi tão sujo que o juiz imaginário apitou falta',
        'acertou o oponente tão baixo que ele sentiu até nos antepassados'
    ],

    'erro':
    [
        'tentou um golpe baixo, mas o oponente estava de proteção. Ele veio preparado.',
        'errou o golpe baixo e acertou o chão. Baixo demais.',
        'foi dar um golpe baixo, o oponente pulou e agora ficou com cara de bobo',
        'tentou algo sujo, mas tropeçou na própria maldade'
    ]
    },

    #VENENOSOS
    'envenenamento':
    {'nome': 'Envenenamento', 'desc': 'Envenena seu inimigo tirando 10% de vida por turno', 'dano': 0, 'chance': 60, 'taxa': 0, 'critico': 0, 'tipo': 'venenoso', 'efeito': listaEfeitos['veneno'], 'chanceEfeito': 100,
    
    'acerto': 
    [
        'jogou uma chuva de veneno no inimigo',
        'deixou o inimigo fortemente envenenado',
        'misturou veneno na bebida do oponente, que bebeu feliz da vida',
        'soprou uma nuvem verde e fedorenta no inimigo'
    ],

    'erro':
    [
        'jogou uma chuva de veneno, NO CHÃO',
        'deixou o inimigo extremamente normal',
        'jogou o veneno, o vento levou de volta e quase se envenenou',
        'ofereceu uma bebida envenenada, o oponente recusou educadamente'
    ]
    },

    #INSETOS

    #SAGRADOS

    #PESADOS

    'barrigada':
    {'nome': 'Barrigada', 'desc': 'Se joga de barriga, causa 1.7x seu ataque, sem critico', 'dano': 1.7, 'chance': 60, 'taxa': 0, 'critico': 0, 'tipo': 'pesado', 'efeito': 'sem',

    'acerto':
    [
        'tomou distância, correu e se jogou de barriga em cima do oponente',
        'deu um pulo e caiu de barriga, o chão tremeu e o oponente também',
        'se jogou de barriga como quem pula numa piscina, mas a piscina era o oponente',
        'mergulhou de barriga no oponente e ainda deslizou alguns metros'
    ],

    'erro':
    [
        'se jogou de barriga, o oponente saiu da frente e o chão levou o golpe sozinho',
        'pulou para a barrigada, mas a barriga chegou antes do resto e ele travou no meio do ar',
        'se jogou com tudo, errou o oponente e ficou preso no chão sem conseguir levantar',
        'tomou impulso para a barrigada, escorregou numa casca de banana e caiu de costas'
    ]
    },

    #VAMPIRISMO


}

#Ordem para as curas:
#NOME, DESCRICAO, %VIDA, CHANCE DE ACERTO, FRASES ACERTO, ERRO


listaCuras = [
    {'nome': 'Cura Simples', 'desc': 'Cura 20% e tem 95% de SUCESSO', 'vida': 20, 'chance': 95, 
    'acerto': 
    [
        'curou 100% tomando uma xicara de café bem quentinho, queimou a lingua e perdeu 80% dos 100%',
        'comeu um pacotão de doritos, ganhou 20% de cura e 10 anos a menos de expectativa de vida', 
        'tentou meditar, escorregou, por sorte caiu de cara em uma poça deixada pela poção de cura que caiu de seu bolso, curou 20%',
        'tomou um copo de água gelada com calma, se sentiu renovado e curou 20%',
        'tirou uma soneca de 30 segundos no meio da luta, o oponente respeitou o descanso, curou 20%',
        'achou um bolo amassado no bolso, comeu mesmo assim e curou 20%',
        'comeu uma maçã por dia como manda o ditado, o médico ficou longe e curou 20%',
        'ouviu uma música antiga no fone de ouvido, bateu a nostalgia e curou 20%',
        'tomou um chá de camomila que apareceu sabe-se lá de onde, curou 20%',
    ],
    'erro':
    [
        'queimou a boca no primeiro gole de café, achando que o café nunca mudaria, não tentou novamente, 0% de vida recuperada',
        'foi comer um pacote de doritos, viu que tinha bolor e jogou fora(que nojo!), nada aconteceu',
        'meditou, mas pelo visto isso não cura nossos verdadeiros problemas, nada aconteceu.',
        'foi tomar um copo de água gelada, engasgou e passou 10 segundos tossindo, 0% de vida recuperada',
        'abriu o bolso para pegar um lanche, mas o oponente já tinha comido, nada aconteceu',
        'tentou fazer um alongamento para relaxar, travou a coluna, nada aconteceu',
        'respirou fundo para se acalmar, lembrou da conta de luz atrasada e piorou, 0% de vida recuperada',
        'foi ouvir uma música para relaxar, a bateria do fone acabou, nada aconteceu',
        'preparou um chá, esqueceu de tirar o saquinho e virou uma água marrom, 0% de vida recuperada',
    ],
    },

    {'nome': 'Cura Media', 'desc': 'Cura 50% e tem 50% de SUCESSO', 'vida': 65, 'chance': 50, 
    'acerto': 
    [
        'dormiu por 5 horas, como o adversario era muito generoso, acabou por não atrapalhar, curou 65% de vida',
        'carregou seu ki e recuperou 65% de vida', 
        'pesquisou metodos de como conquistar FÊMEAS, deu tudo errado, bebeu cachaça e recuperou 65% de vida',
        'assistiu vídeos de gatinhos por 5 minutos, o adversário assistiu junto, curou 65% de vida',
        'fez um churrasco no meio da luta, até o oponente pegou um espetinho, curou 65% de vida',
        'rezou para todos os santos que conhecia, um deles atendeu, curou 65% de vida',
        'tomou um banho de cachoeira que apareceu do nada, o roteirista agradeceu, curou 65% de vida',
        'encontrou um sofá no meio do campo de batalha, deitou e curou 65% de vida',
        'ligou pra mãe, ela mandou se agasalhar e preparou um caldo por telepatia, curou 65% de vida',
    ],
    'erro':
    [
        'tentou dormir, o adversario obviamente não deixou, 0% de vida recuperada',
        'tentou carregar seu ki, INACREDITAVELMENTE, ele não estava em Dragon Ball, nada aconteceu',
        'pesquisou metodos de como conquistar FÊMEAS, percebeu que o problema estava nele, desistiu.',
        'foi assistir vídeos de gatinhos, o wifi caiu no meio, nada aconteceu',
        'tentou fazer um churrasco, esqueceu o carvão e ficou só com a fome, 0% de vida recuperada',
        'rezou para todos os santos, mas estava fora do horário de atendimento, nada aconteceu',
        'foi tomar banho de cachoeira, era só uma goteira, 0% de vida recuperada',
        'deitou no sofá que achou, era uma miragem, caiu de bunda no chão, nada aconteceu',
        'ligou pra mãe, ela só queria saber se ele já tinha comido, 0% de vida recuperada',
    ],
    },
    ]

#Ordem para as defesas:
#NOME, DESCRICAO, CHANCE DE ACERTO, FRASES ACERTO, ERRO

listaDefesas = [

]


