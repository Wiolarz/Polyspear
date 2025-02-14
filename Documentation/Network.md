# Network -- technical description and functionality addition manual

## Introduction

First thing is that we do not use default Godot's network mode with RPC etc.
We use *Enet* library, which is available in Godot (it's also backend for default
mode).

Some parts of this document are detailed technical information, but don't
worry, if you don't understand them, you can just skip them because probably
you don't need them. The most important part is the manual explaining how to
add new features to network engine.

## Short architecture description

There are 2 types of commands (file `Scripts/Multiplayer/command.gd`)
transferred over network:

* Orders -- sent from server to clients. Typically they are very authoritative
  and client's refusal to obey them ends with *desync*. They can also bring
  some useful information like chat messages etc. Orders are implemented in
  directory `Scripts/Multiplayer/Commands/Orders/`.
* Requests -- sent from clients to server. They can be anything client wants
  to request from server, for example making a game move or sending something
  to chat. Server decides whether it fulfills these requests (for example,
  illegal game move will be rejected). Some of requests have their
  corresponding orders, for example, requesting a chat message makes server
  broadcast it to all clients. They are implemented in directory
  `Scripts/Multiplayer/Commands/Requests/`.

## Communication description

### Server setup

Everything begins with function
`server_listen(address : String, port : int, username : String)` in network
manager (`Scripts/Multiplayer/NEW_manager.gd`), which under the hoods calls
`make_server()` -- the function switching network manager to server mode, and
then `listen(address : String, port : int, username : String)`
in `Scripts/Multiplayer/server.gd:34`, which uses *Enet* stuff.

The `server_listen` function needs information about listen address and port
(classic network L3/L4 stuff). It also takes username for player (*peer*) who
is the host (and therefore an admin).

### Connection to server

This is a bit more complicated procedure. We start it with function
`client_connect_and_login(address : String, port : int, login : String)`
w network managerze.

#### Nawiązanie połączenia na warstwie OSI 4 i 5/6/7

Najpierw klient musi w ogóle nawiązać połączenie z serwerem na poziomie 4
(i 5/6/7, bo gdzieś tam bym wrzucił rzeczy związane z ENetem). Wywołuje do tego
`connect_to_server(address : String, port : int) -> void`
w `Scripts/Multiplayer/client.gd:30`.

#### Zalogowanie

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

### Rozgłoszenie czegoś przez serwer STUB

Serwer może wysyłać komendy do klientów (Client komendy). Każda taka komenda
powinna być zserializowanym przez Godota słownikiem godotowym, gdzie pole "name"
jest zarezerwowane dla nazwy komendy. Nazwa komendy musi być taka sama jak nazwa
pliku bez katalogu i rozszerzenia. Np. komenda '

### Prośba klienta do serwera o coś STUB

### Może dodatkowo wylogowanie?? Mało ważne na razie wsm STUB

## Jak dodać nową akcję (Action) w grze (wcześniej ruch (Move)) STUB

## Jak dodać zupełnie nową komendę STUB

## Słownik

* desync -- sytuacja, w której stan gry u klienta i u serwera różnią się
  na tyle, że nie jest możliwa dalsza współpraca. Gdy klient sczai się, że ma
  desync, prosi serwer o ponowne wysłanie stanu świata
  (`Scripts/Multiplayer/ServerCommands/requested_state_sync.gd`). TODO Jeśli
  serwer dostanie prośbę o nieprawidłowy ruch, trzeba zrobić, że wysyła
  do klienta info o tym, że ruch jest zły.
  Patrz:
  * `Scripts/Multiplayer/client.gd:121` -- `desync() -> void`
  * `Scripts/Multiplayer/NET_manager.gd:46` -- `desync() -> void`
