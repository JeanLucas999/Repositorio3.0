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

tiposAtuais = ['basico', 'humanoide', 'voador', 'devoto', 'animal', 'perverso', 'venenoso', 'inseto', 'sagrado', 'pesado', 'vampirismo', 'magico', 'genial', 'bandido', 'pequeno', 'fogo', 'agua']




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

    'cotovelada':
    {'nome': 'Cotovelada', 'desc': 'Acerta uma cotovelada, causando 1.2x seu ataque', 'dano': 1.2, 'chance': 80, 'taxa': 10, 'critico': 1.6, 'tipo': 'humanoide', 'efeito': 'sem',

    'acerto':
    [
        'deu uma cotovelada nas costelas do oponente',
        'girou o corpo e acertou uma cotovelada no queixo',
        'fingiu que ia apertar a mão e deu uma cotovelada',
        'cotovelou o oponente e fez cara de paisagem'
    ],

    'critou':
    [
        'deu uma cotovelada tão forte que o oponente ouviu o próprio osso reclamar',
        'acertou a cotovelada no queixo e o oponente viu estrelinhas',
        'cotovelou com tanta classe que o oponente quase pediu bis',
        'acertou uma cotovelada tão precisa que o oponente sentiu nos dentes'
    ],

    'erro':
    [
        'foi dar uma cotovelada e bateu o cotovelo na parede, o famoso "osso da alegria"',
        'tentou cotovelar, o oponente se abaixou e ele ficou com o cotovelo no ar',
        'girou para a cotovelada e girou tanto que ficou de costas para o oponente',
        'errou a cotovelada e agora está soprando o cotovelo dolorido'
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

    'ventania':
    {'nome': 'Ventania', 'desc': 'Bate as asas e cria uma ventania, causando 0.8x seu ataque', 'dano': 0.8, 'chance': 95, 'taxa': 10, 'critico': 1.4, 'tipo': 'voador', 'efeito': 'sem',

    'acerto':
    [
        'bateu as asas e uma ventania jogou o oponente para trás',
        'bateu as asas com tanta vontade que levantou poeira e o oponente tossiu',
        'criou um vendaval e o oponente rodou feito saco plástico',
        'bateu as asas e despenteou o oponente, que levou o dano a sério'
    ],

    'critou':
    [
        'bateu as asas e criou um furacão pessoal que lançou o oponente longe',
        'criou uma ventania tão forte que o oponente voou e ainda levou o dano de volta',
        'bateu as asas e o oponente grudou na parede por alguns segundos',
        'criou uma tempestade de penas e poeira que deixou o oponente girando'
    ],

    'erro':
    [
        'bateu as asas, mas o vento soprou ao contrário e voltou na própria cara',
        'bateu as asas e só espalhou as penas pelo chão',
        'tentou criar uma ventania, mas só saiu uma brisa de domingo',
        'bateu as asas, ficou cansado e sentou para descansar'
    ]
    },

    #DEVOTOS
    'cabecadaZen':
    {'nome': 'Cabeçada Zen', 'desc': 'Medita e dá uma cabeçada precisa, 1.3x seu ataque', 'dano': 1.3, 'chance': 50, 'taxa': 30, 'critico': 1.8, 'tipo': 'devoto', 'efeito': 'sem',

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
        'deu uma cabeçada que ecoou pela montanha inteira',
        'deu uma cabeçada tão pura que o oponente viu a luz no fim do túnel',
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

    'oracaoFuriosa':
    {'nome': 'Oração Furiosa', 'desc': 'Reza com tanta fé que machuca, causando 1.6x seu ataque', 'dano': 1.6, 'chance': 35, 'taxa': 25, 'critico': 1.8, 'tipo': 'devoto', 'efeito': 'sem',

    'acerto':
    [
        'rezou tão alto que o oponente levou um susto e o golpe junto',
        'juntou as mãos, gritou um amém e acertou o oponente com um raio de fé',
        'rezou um terço inteiro e entregou a conta ao oponente',
        'invocou a fé e acertou o oponente com um sermão que doeu de verdade'
    ],

    'critou':
    [
        'rezou com tanta devoção que um raio de luz atingiu o oponente em cheio',
        'rezou uma oração tão poderosa que o oponente se ajoelhou sem querer',
        'rezou com tanta fé que até o chão pediu perdão',
        'gritou um amém tão forte que a montanha respondeu'
    ],

    'erro':
    [
        'começou a rezar, mas esqueceu a letra e inventou no improviso, nada aconteceu',
        'rezou com tanta fé que o oponente aproveitou para ir ao banheiro',
        'rezou com fervor, mas o santo estava de folga',
        'gritou um amém, o oponente respondeu "amém" também e nada aconteceu'
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

    'patada':
    {'nome': 'Patada', 'desc': 'Acerta uma patada, causando 1.2x seu ataque', 'dano': 1.2, 'chance': 70, 'taxa': 10, 'critico': 1.7, 'tipo': 'animal', 'efeito': 'sem',

    'acerto':
    [
        'deu uma patada que deixou o oponente com cara de tapa',
        'arranhou o oponente e saiu correndo',
        'saltou e acertou uma patada no peito do oponente',
        'bateu a pata no oponente como quem espanta mosca'
    ],

    'critou':
    [
        'deu uma patada tão forte que deixou marcas até na armadura',
        'arranhou o oponente com tanta fúria que ele perdeu a pose',
        'pulou e acertou três patadas seguidas antes de o oponente piscar',
        'deu uma patada tão violenta que o oponente rodou no ar'
    ],

    'erro':
    [
        'tentou dar uma patada, mas ficou preso nas próprias unhas',
        'foi arranhar, o oponente deu um passo para trás e ele caiu de focinho',
        'saltou para a patada e se distraiu com uma borboleta',
        'deu uma patada no ar e fingiu que estava se espreguiçando'
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
        'deu um golpe tão baixo que a torcida vaiou. Mas funcionou.',
        'deu um golpe tão sujo que o juiz imaginário apitou falta',
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

    'areiaNosOlhos':
    {'nome': 'Areia nos Olhos', 'desc': 'Joga areia nos olhos, causa 0.8x seu ataque e alto crítico', 'dano': 0.8, 'chance': 85, 'taxa': 10, 'critico': 2.0, 'tipo': 'perverso', 'efeito': 'sem',

    'acerto':
    [
        'jogou areia nos olhos do oponente e aproveitou para bater',
        'abaixou, pegou um punhado de terra e jogou na cara do oponente',
        'gritou "olha ali!" e jogou areia quando o oponente olhou',
        'jogou pimenta nos olhos do oponente, que agora chora feito novela'
    ],

    'critou':
    [
        'jogou areia com tanta pontaria que o oponente ficou cego por um instante e levou todos os golpes',
        'jogou areia que entrou em lugares que o oponente nem sabia que tinha',
        'acertou areia no olho e ainda deu um sorrisinho malvado',
        'jogou uma nuvem de areia tão grande que o oponente tossiu e levou dano extra'
    ],

    'erro':
    [
        'jogou areia, o vento mudou e a poeira voltou toda para a própria cara',
        'tentou jogar areia, mas era só um punhado de grama',
        'jogou areia nos olhos do oponente, que estava de óculos de proteção',
        'gritou "olha ali!", o oponente olhou, não viu nada e olhou de volta bem bravo'
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

    'espinhoToxico':
    {'nome': 'Espinho Tóxico', 'desc': 'Lança um espinho venenoso, causando 0.7x seu ataque e chance de envenenar', 'dano': 0.7, 'chance': 80, 'taxa': 15, 'critico': 1.3, 'tipo': 'venenoso', 'efeito': listaEfeitos['veneno'], 'chanceEfeito': 40,

    'acerto':
    [
        'lançou um espinho tóxico que acertou o oponente no braço',
        'cravou um espinho verde e brilhante no oponente',
        'atirou uma chuva de espinhos e um deles pegou',
        'enfiou um espinho no oponente e saiu assobiando'
    ],

    'critou':
    [
        'atirou um espinho com tanta força que atravessou a armadura',
        'acertou um espinho em cheio e o oponente ficou meio esverdeado',
        'lançou vários espinhos de uma vez e todos acertaram',
        'lançou um espinho tão certeiro que o oponente jurou ter visto a vida passar'
    ],

    'erro':
    [
        'lançou um espinho, mas ele ricocheteou e voltou para o próprio pé',
        'tentou atirar um espinho, mas era um palito de dente',
        'atirou o espinho e acertou uma pedra, que ficou envenenada (e sem importância)',
        'preparou o espinho, mas picou o próprio dedo e parou para reclamar'
    ]
    },

    #INSETOS
    'enxame':
    {'nome': 'Enxame', 'desc': 'Chama um enxame de insetos, causando 1.1x seu ataque', 'dano': 1.1, 'chance': 70, 'taxa': 15, 'critico': 1.4, 'tipo': 'inseto', 'efeito': 'sem',

    'acerto':
    [
        'chamou um enxame que picou o oponente por todos os lados',
        'soltou um enxame de besouros que cobriu o oponente inteiro',
        'chamou um enxame que zumbiu tão alto que o oponente se desesperou e levou dano',
        'chamou os amigos insetos para uma festa e o convidado de honra era o oponente'
    ],

    'critou':
    [
        'fez um enxame que cobriu o oponente tão completamente que ele sumiu por alguns segundos',
        'fez milhares de insetos picarem o oponente de uma só vez',
        'chamou um enxame tão grande que escureceu o céu',
        'fez um enxame que foi tão intenso que o oponente jurou nunca mais comer mel'
    ],

    'erro':
    [
        'chamou o enxame, mas eles estavam em horário de almoço e não vieram',
        'chamou, o enxame veio, confundiu o alvo e picou o próprio dono',
        'chamou o enxame, mas só apareceu uma mosca perdida',
        'chamou, o enxame se distraiu com uma lâmpada e esqueceu do oponente'
    ]
    },

    #SAGRADOS
    'luzDivina':
    {'nome': 'Luz Divina', 'desc': 'Invoca uma luz sagrada, causando 1.2x seu ataque', 'dano': 1.2, 'chance': 65, 'taxa': 20, 'critico': 1.8, 'tipo': 'sagrado', 'efeito': 'sem',

    'acerto':
    [
        'invocou uma luz do céu que queimou o oponente',
        'abriu os braços e uma luz sagrada atingiu o oponente',
        'invocou uma luz divina que caiu do céu e deixou o oponente com cara de quem viu um fantasma',
        'brilhou tanto que o oponente teve que cobrir os olhos e levou o dano'
    ],

    'critou':
    [
        'fez uma luz divina cair com tanta força que o oponente viu o paraíso por um segundo',
        'conjurou um raio sagrado que atravessou o oponente, que ficou com cheiro de queimado',
        'fez o céu se abrir e uma luz dourada acertou o oponente em cheio',
        'fez uma luz tão forte que até os anjos pediram para baixar o brilho'
    ],

    'erro':
    [
        'invocou a luz divina, mas o céu estava nublado e só caiu uma gota',
        'invocou uma luz sagrada que acertou o chão e deixou a grama mais verde',
        'invocou a luz, mas ela foi resolver outro assunto e nunca chegou',
        'tentou brilhar, mas a lanterna estava sem pilha'
    ]
    },

    #PESADOS

    'barrigada':
    {'nome': 'Barrigada', 'desc': 'Se joga de barriga, causa 1.6x seu ataque, sem critico', 'dano': 1.6, 'chance': 50, 'taxa': 0, 'critico': 0, 'tipo': 'pesado', 'efeito': 'sem',

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

    'pisao':
    {'nome': 'Pisão', 'desc': 'Pisa com toda a força, causa 1.5x seu ataque mas com baixo crítico', 'dano': 1.5, 'chance': 50, 'taxa': 15, 'critico': 1.05, 'tipo': 'pesado', 'efeito': 'sem',

    'acerto':
    [
        'levantou o pé e deu um pisão que fez o chão tremer',
        'deu um pisão no pé do oponente, que pulou de dor',
        'pisou no oponente com a delicadeza de um elefante',
        'bateu o pé com tanta força que o oponente quicou'
    ],

    'critou':
    [
        'deu um pisão tão forte que abriu uma rachadura no chão',
        'deu um pisão que ecoou pela arena inteira e o oponente sentiu nos ossos',
        'pisou com tanta força que o oponente afundou meio metro',
        'deu um pisão tão pesado que até os vizinhos reclamaram'
    ],

    'erro':
    [
        'levantou o pé com muita força, mas perdeu o equilíbrio e caiu sentado',
        'deu um pisão no chão e o oponente nem tremeu',
        'foi pisar no oponente, mas pisou numa pedrinha e ficou pulando num pé só',
        'deu um pisão tão forte que o próprio pé ficou dolorido'
    ]
    },

    #VAMPIRISMO
    'sugada':
    {'nome': 'Sugada', 'desc': 'Morde e suga sangue, causa 1x seu ataque e curando parte do dano', 'dano': 1, 'chance': 75, 'taxa': 10, 'critico': 1.2, 'tipo': 'vampirismo', 'efeito': 'sem',

    'acerto':
    [
        'cravou os caninos no pescoço do oponente e bebeu até se satisfazer',
        'sugou o sangue do oponente e fez uma careta de gosto estranho',
        'deu uma mordida elegante e bebeu um gole de sangue',
        'puxou o oponente e sugou o sangue como quem toma um suco'
    ],

    'critou':
    [
        'sugou tanto sangue que o oponente ficou pálido e ele ficou corado',
        'bebeu o sangue do oponente de uma vez só, estilo canudinho',
        'deu uma mordida tão profunda que o oponente jurou ouvir o próprio coração parando',
        'sugou o sangue com tanta vontade que o oponente ficou meio murcho'
    ],

    'erro':
    [
        'foi sugar o sangue, mas o oponente estava com alho no bolso',
        'tentou morder o pescoço, mas pegou só a gola da armadura',
        'sugou o sangue, mas estava azedo e ele cuspiu tudo',
        'tentou sugar o sangue e engasgou com um pelo'
    ]
    },

    #MAGICO
        'raioArcano':
    {'nome': 'Raio Arcano', 'desc': 'Conjura um raio mágico, causando 1.3x seu ataque', 'dano': 1.3, 'chance': 70, 'taxa': 20, 'critico': 1.8, 'tipo': 'magico', 'efeito': 'sem',

    'acerto':
    [
        'estalou os dedos e um raio arcano atingiu o oponente',
        'recitou um feitiço e um raio roxo acertou o oponente',
        'apontou o cajado e soltou um raio que fez o oponente dançar',
        'conjurou um raio e acertou o oponente que estava distraído'
    ],

    'critou':
    [
        'conjurou um raio arcano tão potente que o oponente ficou com o cabelo em pé',
        'invocou um relâmpago roxo que cortou o céu e acertou o oponente em cheio',
        'lançou um feitiço tão forte que o próprio mago se assustou',
        'acertou um raio no oponente e ainda sobrou energia para acender uma lâmpada'
    ],

    'erro':
    [
        'recitou o feitiço, mas errou uma palavra e saiu só uma faísca',
        'apontou o cajado e saiu uma fumacinha, nada mais',
        'soltou um raio, mas acertou uma árvore que já estava queimada',
        'conjurou o feitiço, mas esqueceu de colocar a energia e nada aconteceu'
    ]
    },

    #GENIAL

    'planoGenial':
    {'nome': 'Plano Genial', 'desc': 'Cria um plano perfeito, 0.9x seu ataque, baixo dano, grandes chances', 'dano': 0.9, 'chance': 95, 'taxa': 40, 'critico': 1.6, 'tipo': 'genial', 'efeito': 'sem',

    'acerto':
    [
        'montou um plano perfeito e acertou o oponente em um ponto fraco',
        'calculou a trajetória, ajustou o ângulo e acertou em cheio',
        'fez um desenho no chão, o oponente pisou e levou o golpe',
        'teve uma ideia genial: bater no oponente por trás'
    ],

    'critou':
    [
        'executou um plano tão genial que o oponente demorou a entender o que tinha acontecido',
        'calculou tudo ao milímetro e o golpe acertou o ponto exato',
        'executou um plano que deu tão certo que até o inimigo elogiou depois',
        'previu o movimento do oponente com três turnos de antecedência'
    ],

    'erro':
    [
        'traçou um plano perfeito, só esqueceu de considerar o oponente se mexendo',
        'calculou a trajetória, errou uma conta e acertou a própria sombra',
        'montou um plano genial, mas esqueceu onde deixou a anotação',
        'bolou um plano, mas o oponente decidiu não seguir o roteiro'
    ]
    },

    #BANDIDOS
    'assalto':
    {'nome': 'Assalto', 'desc': 'Assalta o inimigo, causa 1.2x seu ataque e alto crítico', 'dano': 1.2, 'chance': 85, 'taxa': 10, 'critico': 2.0, 'tipo': 'bandido', 'efeito': 'sem',

    'acerto':
    [
        'saiu das sombras e acertou o oponente com uma facada nas costas',
        'gritou "PASSA TUDO!" e deu um soco no oponente',
        'distraiu o oponente com uma moeda e atacou pelas costas',
        'assaltou o oponente e levou o dano de brinde'
    ],

    'critou':
    [
        'deu uma facada tão rápida que o oponente nem viu de onde veio',
        'assaltou o oponente tão bem que ele ainda agradeceu pelo atendimento',
        'deu um golpe pelas costas tão limpo que até o juiz aplaudiu',
        'levou o dinheiro, a dignidade e o dano crítico do oponente'
    ],

    'erro':
    [
        'gritou "PASSA TUDO!", o oponente estava sem nada e ficou com pena',
        'tentou assaltar o oponente, mas ele era pobre e riu da situação',
        'foi atacar pelas costas, o oponente se virou e os dois ficaram se olhando',
        'tentou roubar, mas pegou só a bolsa errada e saiu correndo'
    ]
    },

    #PEQUENOS
    'chuteNaCanela':
    {'nome': 'Chute na Canela', 'desc': 'Chuta a canela, causa 1x seu ataque e quase nunca erra', 'dano': 1, 'chance': 99, 'taxa': 50, 'critico': 1.3, 'tipo': 'pequeno', 'efeito': 'sem',

    'acerto':
    [
        'deu um chute na canela do oponente e saiu correndo',
        'correu entre as pernas do oponente e acertou a canela',
        'chutou a canela com todas as suas forças, que não são muitas',
        'pulou, bateu na canela do oponente e fez pose de herói'
    ],

    'critou':
    [
        'deu um chute tão certeiro que o oponente pulou num pé só por uma hora',
        'acertou a canela com tanta força que o oponente fez uma dança involuntária',
        'deu um chute na canela tão forte que o oponente chorou escondido',
        'acertou o chute e o oponente prometeu nunca mais subestimar os baixinhos'
    ],

    'erro':
    [
        'correu para chutar a canela, mas o oponente nem sentiu, sério isso?',
        'tentou chutar, mas o oponente levantou a perna e o baixinho passou por baixo',
        'chutou a canela, mas era só uma perna de pau e ele se machucou',
        'foi chutar, escorregou e rolou até uma poça'
    ]
    },

    #FOGO
    'temperaturaElevada':
    {'nome': 'Temperatura Elevada', 'desc': 'Esquenta o ambiente, causa 1.4x seu ataque', 'dano': 1.4, 'chance': 70, 'taxa': 10, 'critico': 1.7, 'tipo': 'fogo', 'efeito': 'sem',

    'acerto':
    [
        'esquentou o ambiente até o oponente começar a suar em bicas e levar o dano',
        'soltou uma onda de calor e o oponente ficou vermelho feito pimentão',
        'aumentou a temperatura e o oponente pediu um ventilador, mas levou dano mesmo assim',
        'esquentou tudo ao redor e o oponente sentiu como se estivesse num forno'
    ],

    'critou':
    [
        'subiu a temperatura tanto que o oponente viu miragem e ainda levou o dano em dobro',
        'soltou um calor tão intenso que até o chão ficou derretido e o oponente saiu pulando',
        'esquentou a arena inteira e o oponente jurou que estava no deserto do Saara',
        'elevou a temperatura ao nível "churrasco" e o oponente quase foi servido com farofa'
    ],

    'erro':
    [
        'tentou esquentar o ambiente, mas só conseguiu ficar com calor ele mesmo',
        'subiu a temperatura, mas o oponente trouxe um leque e nem sentiu',
        'esquentou tanto que o próprio suor apagou o fogo, nada aconteceu',
        'tentou criar uma onda de calor, mas só saiu um bafo quente de cansaço'
    ]
    },

    #AGUA
    'miniTsunami':
    {'nome': 'Mini Tsunami', 'desc': 'Cria uma onda, causando 1.6x seu ataque', 'dano': 1.6, 'chance': 40, 'taxa': 15, 'critico': 1.8, 'tipo': 'agua', 'efeito': 'sem',

    'acerto':
    [
        'invocou uma onda de tamanho médio que arrastou o oponente alguns metros',
        'criou um mini tsunami que molhou o oponente até a alma',
        'soltou uma onda que derrubou o oponente e levou a espada dele de brinde',
        'fez uma ondinha de respeito e o oponente saiu rodando feito meia na máquina de lavar'
    ],

    'critou':
    [
        'criou uma onda tão grande que o "mini" do nome virou mentira',
        'invocou um tsunami com tanta força que o oponente foi parar do outro lado da arena',
        'criou uma onda tão forte que até os peixes ficaram assustados',
        'soltou uma onda tão grande que o oponente achou que estava no Titanic'
    ],

    'erro':
    [
        'invocou a onda, mas ela se perdeu no caminho e foi para a casa do vizinho',
        'criou um tsunami tão mini que só molhou o sapato do oponente',
        'invocou uma onda com força, mas ela voltou e arrastou o próprio invocador',
        'tentou criar um tsunami, mas só saiu um respingo de torneira'
    ]
    },
}

#Ordem para as curas:
#NOME, DESCRICAO, %VIDA, CHANCE DE ACERTO, FRASES ACERTO, ERRO


listaCuras = [
    {'nome': 'Cura Simples', 'desc': 'Cura 20% e tem 90% de SUCESSO', 'vida': 20, 'chance': 90, 
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
        'tomou um banho quente rapidinho entre um golpe e outro, curou 20%',
        'comeu uma bolacha de água e sal que achou no bolso, curou 20%',
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
        'foi tomar um banho quente, a água estava gelada e ele saiu correndo, 0% de vida recuperada',
        'abriu a bolacha de água e sal, estava mole, jogou fora e nada aconteceu',
    ],
    },

    {'nome': 'Cura Media', 'desc': 'Cura 50% e tem 50% de SUCESSO', 'vida': 50, 'chance': 50, 
    'acerto': 
    [
        'dormiu por 5 horas, como o adversario era muito generoso, acabou por não atrapalhar, curou 50% de vida',
        'carregou seu ki e recuperou 50% de vida', 
        'pesquisou metodos de como conquistar FÊMEAS, deu tudo errado, bebeu cachaça e recuperou 50% de vida',
        'assistiu vídeos de gatinhos por 5 minutos, o adversário assistiu junto, curou 50% de vida',
        'fez um churrasco no meio da luta, até o oponente pegou um espetinho, curou 50% de vida',
        'rezou para todos os santos que conhecia, um deles atendeu, curou 50% de vida',
        'tomou um banho de cachoeira que apareceu do nada, o roteirista agradeceu, curou 50% de vida',
        'encontrou um sofá no meio do campo de batalha, deitou e curou 50% de vida',
        'ligou pra mãe, ela mandou se agasalhar e preparou um caldo por telepatia, curou 50% de vida',
        'foi ao mercado no meio da luta, comprou um pão de queijo quentinho e curou 50% de vida',
        'ganhou um abraço de um desconhecido que passava, curou 50% de vida',
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
        'foi ao mercado, o pão de queijo tinha acabado, 0% de vida recuperada',
        'pediu um abraço, o desconhecido saiu correndo, nada aconteceu',
    ],
    },

    {'nome': 'Cura Avancada', 'desc': 'Cura 100% e tem 10% de SUCESSO', 'vida': 100, 'chance': 10, 
    'acerto': 
    [
        'invocou um anjo da guarda que estava de plantão, ele pediu desculpa pelo atraso e curou 100% de vida',
        'encontrou uma fonte da juventude, bebeu um gole e curou 100% de vida',
        'dormiu em uma cama king size que apareceu do nada, acordou novinho em folha e curou 100% de vida',
        ': o roteirista sentiu pena, reescreveu a cena e curou 100% de vida',
        'comeu o prato do dia do restaurante mais caro do reino, curou 100% de vida e deixou a carteira vazia',
        'meditou por 7 dias em 7 segundos, atingiu a iluminação e curou 100% de vida',
        'achou uma poção lendária dentro de um baú esquecido, curou 100% de vida',
        'recebeu uma ligação da avó dizendo que ia ficar tudo bem, curou 100% de vida',
        'foi atingido por um raio curativo do nada, curou 100% de vida e ficou com o cabelo em pé',
        'passou uma semana de férias na praia em um piscar de olhos, curou 100% de vida',
        'fez um pacto com um espírito suspeito, curou 100% de vida e nem leu os termos do contrato',
    ],
    'erro':
    [
        'invocou o anjo da guarda, mas só caiu na caixa postal, 0% de vida recuperada',
        'achou uma fonte da juventude, mas era só uma fonte de praça com água suja, nada aconteceu',
        'deitou numa cama king size, era uma miragem e ele caiu de cara no chão, 0% de vida recuperada',
        'esperou o roteirista ter pena, mas ele estava de folga, nada aconteceu',
        'foi comer no restaurante mais caro do reino, mas esqueceu a carteira e foi expulso, 0% de vida recuperada',
        'tentou meditar por 7 dias, o oponente não respeitou nem 7 segundos, nada aconteceu',
        'abriu o baú esquecido, só tinha uma meia furada, 0% de vida recuperada',
        'ligou para a avó, ela não atendeu porque estava vendo novela, nada aconteceu',
        'ficou esperando um raio curativo debaixo de uma árvore, só tomou chuva, 0% de vida recuperada',
        'foi viajar para a praia, o mapa estava de cabeça para baixo e terminou numa montanha, nada aconteceu',
        'foi fazer um pacto com um espírito, mas o espírito pediu desconto e ele saiu sem nada, 0% de vida recuperada',
    ],
    },
    ]

#Ordem para as defesas:
#NOME, DESCRICAO, CHANCE DE ACERTO, FRASES ACERTO, ERRO

listaDefesas = [

]


