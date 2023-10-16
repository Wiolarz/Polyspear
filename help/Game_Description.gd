# Game Description
var Podstawowa_Wersja
"""
W grze wcielamy się w czarodzieja
który zna kung-fu i podrózuje przez fantastyczne krainy


W swoich podróżach regularnie walczy z potworami
ale żeby się nie męczyć rzuca w każdego przed walką
jednorazowym magicznym zwojem, który wystrzeliwywuje magiczny pocisk
który moze być w stanie zabić potwora.
Celem gry jest odpowiednio dobierać zwoje do szacowanego poziomu zagrożenia, by
nie zachować najmocniejsze zaklęcia na najsilniejszych przeciwników.



"""


var Zaawansowana_wersja
'''
W tej wersji Gracz zamiast strzelać fireballem przyzywa swojego żywioła by ten
uporał się z zagrożeniem.


Strony konfliktu, zamiast być pojedynczą wartością siły, stają się jednostkami z życiem i siła. Obrażenia są zadawane równocześnie i remis jest korzystny dla gracza.
Np. walka między 4/5 a 2/7 wyglądać będzie tak:
4/5   | 2/7
4/3   | 2/3
4/1  | 2/-1
Wygrała jednostka gracza



Losowe jednostki generujemy tak: Goblin z siłą 10, zaczyna ze statystykami 1/1
Potem losujemy ile dostanie ataku a ile życie tak by ich suma była równa jego sile.

(Przykładowe 2 rozwiązania w notatkach)

'''
