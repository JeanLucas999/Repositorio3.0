import urllib
from urllib import request

try:
    site = urllib.request.urlopen('http://www.pudim.com.br')
except:
    print ('ERRO')
else:
    print ('SITE ACESSIVEL')