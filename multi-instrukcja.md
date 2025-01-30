# Siema, insktukacja o co chodzi w tym multi

# Wstęp

Zacznę od tego, że nasze w multi w Poly Spearze nie używa domyślnego trybu
z RPC, tylko używamy zaszytej w Godocie biblioteki ENet.

W tym opisie/instruckji w niektórych miejscach wchodzę trochę w techniczne 
szczegóły, aczkolwiek robię to w takich miejscach, gdzie jeśli nie są one dla
Ciebie zrozumiałe, to nie ba problemu -- nie musisz nawet ich czytać xD.
Najważniejsze dla Ciebie będą sekcje, gdzie opisałem, jak dodawać nowe rzeczy 
do multi.

# Skrót

Mamy dwa rodzaje komend (plik `Scripts/Multiplayer/command.gd`) lecących
po sieci:

* Komendy serwera (ServerCommands) wysyłane przez klientów do serwera 
  i wykonywane (albo i nie) przez serwer. Zwykle są to requesty klientów o coś,
  np. ruch albo napisanie czegoś na czacie. Często (ale nie zawsze) serwer ma
  jakąś komendę klienta, która służy do rozgłoszenia tego, co zrobił klient,
  jeśli serwer na to pozwolił. Tym komendom odpowiadają pliki w folderze
  `Scripts/Multiplayer/ServerCommands`.
* Komendy klienta (ClientCommands) wysyłane przez serwer do klientów. W zasadzie
  są to rozkazy dla klientów, które powinni oni wykonać (nie wykonanie zwykle
  skończy się desync'iem) albo informacje o tym, co się dzieje (np. wpisy
  na czacie). Tym komendom odpowiadają pliki w folderze
  `Scripts/Multiplayer/ClientCommands`.

TODO Ogólnie jak chodzi o te nazwy, to bym je zmienił, bo równie dobrze
serwerowe i klienckie komendy mogłyby być na odwrót (może nawet byłoby tak
lepiej). Chodzi mi teraz o to, żeby dać jakieś zupełnie nowe inne nazwy, które
będą lepiej wskazywały, o co chodzi.

# Opis komunikacji

## Postawienie serwera

Wszytko ogarnia się funkcją
`server_listen(address : String, port : int, username : String)` w network
managerze (`Scripts/Multiplayer/NEW_manager.gd:52`), która pod spodem odpala
`make_server()` -- funkcję przestawiającą network managera w tryb serwera,
a następnie `listen(address : String, port : int, username : String)`
w `Scripts/Multiplayer/server.gd:34`, która już pracuje na obiektach 
z biblioteki ENet.

Ogólnie chodzi o to, że tam wybieramy adres, port do wystawienia serwera i nick
gracza, który jest domyślnie skojarzony z serwerem.

## Podłączenie się do serwera

Tutaj mamy troszkę bardziej złożoną procedurę. Ogólnie wszystko jest pod funkcją
`client_connect_and_login(address : String, port : int, login : String)`
w network managerze.

### Nawiązanie połączenia na warstwie OSI 4 i 5/6/7.

Najpierw klient musi w ogóle nawiązać połączenie z serwerem na poziomie 4
(i 5/6/7, bo gdzieś tam bym wrzucił rzeczy związane z ENetem). Wywołuje do tego
`connect_to_server(address : String, port : int) -> void`
w `Scripts/Multiplayer/client.gd:30`.

### Zalogowanie

Po tej czynności mamy jednak tylko połączenie w ENecie (chyba 5 warstwa).
Trzeba jeszcze się zalogować. To robi funkcja
`queue_login(desired_username : String) -> void`, która kolejkuje wysłanie
prośby o zalogowanie (później wytłumaczę, czego kolejkujemy komendy wysyłane do 
serwera).

Serwer po dostaniu takiej prośby robi kilka rzeczy:

* Sprawdza, czy prośba jest w porządku.
* Tworzy u siebie sesję gracza (obecnie skojarzenie peera (można powiedzieć, że
  to tutaj taki obiekt pojedynczego połączenia do serwera) z nazwą użytkownika,
  którą sobie wybrał klient).
  * Jeśli nazwa użytkownika jest zajęta przez innego klienta, poprzedni jej
    użytkownik zostaje skickowany.
  * Jeśli nazwa użytkownika jest zajęta przez serwer, serwer odmawia zalogowania
    i kickuje klienta.
* Jeśli wszystko poszło git, serwer wysyła do klienta informacje o nowej sesji
  (`Scripts/Multiplayer/ClientCommands/set_session_command.gd`) i dodatkowe
  informacje (np. obecny stan gry, jeśli taki istnieje) przy użyciu funkcji
  `send_additional_callbacks_to_logging_client(peer : ENetPacketPeer)`.
    
Jak serwer odeśle klientowi sesję, ten ustawia sobie otrzymaną nazwę oraz
"uznaje, że jest zalogowany".

## Rozgłoszenie czegoś przez serwer STUB

Serwer może wysyłać komendy do klientów (Client komendy). Każda taka komenda
powinna być zserializowanym przez Godota słownikiem godotowym, gdzie pole "name"
jest zarezerwowane dla nazwy komendy. Nazwa komendy musi być taka sama jak nazwa
pliku bez katalogu i rozszerzenia. Np. komenda '

## Prośba klienta do serwera o coś STUB

## Może dodatkowo wylogowanie?? Mało ważne na razie wsm STUB

# Jak dodać nową akcję (Action) w grze (wcześniej ruch (Move)) STUB

# Jak dodać zupełnie nową komendę STUB

# Słownik

* desync -- sytuacja, w której stan gry u klienta i u serwera różnią się
  na tyle, że nie jest możliwa dalsza współpraca. Gdy klient sczai się, że ma
  desync, prosi serwer o ponowne wysłanie stanu świata
  (`Scripts/Multiplayer/ServerCommands/requested_state_sync.gd`). TODO Jeśli
  serwer dostanie prośbę o nieprawidłowy ruch, trzeba zrobić, że wysyła 
  do klienta info o tym, że ruch jest zły.
  Patrz:
  * `Scripts/Multiplayer/client.gd:121` -- `desync() -> void`
  * `Scripts/Multiplayer/NET_manager.gd:46` -- `desync() -> void`
