#!/bin/bash

names=(
"Marcel.Chmielewski"
"Alicja.Kujawa"
"Kamil.Piątek"
"Filip.Świątek"
"Klaudia.Kania"
"Katarzyna.Stefaniak"
"Sandra.Domagała"
"Jakub.Kopeć"
"Wiktoria.Kosińska"
"Szymon.Kubiak"
"Paweł.Wojciechowski"
"Mateusz.Wawrzyniak"
"Oliwia.Piotrowska"
"Mila.Jankowska"
"Helena.Sawicka"
"Bartek.Dudek"
"Natalia.Musiał"
"Igor.Przybylski"
"Magdalena.Kujawa"
"Karolina.Stasiak"
"Julia.Kołodziejczyk"
"Paulina.Czajka"
"Kacper.Kozak"
"Michał.Ciesielski"
"Artur.Wróblewski"
"Paweł.Cieślik"
"Szymon.Michalik"
"Franciszek.Michalak"
"Amelia.Dąbrowska"
"Nikodem.Nowak"
"Zbigniew.Bem"
"Ryszard.Kobylarz"
"Dariusz.Kajda"
"Henryk.Żur"
"Mariusz.Imiołek"
"Kazimierz.Sidorowicz"
"Wojciech.Turczyński"
"Robert.Olszański"
"Mateusz.Gaca"
"Marian.Wojdyła"
"Rafał.Ostapowicz"
"Jacek.Zielonka"
"Janusz.Borowy"
"Rafał.Wandzel"
"Jacek.Zemła"
"Janusz.Telega"
"Mirosław.Łęgowski"
"Maciej.Boguszewski"
"Sławomir.Fiałkowski"
"Jarosław.Toczek"
"Kamil.Zabłocki"
"Wiesław.Grabka"
"Roman.Sosiński"
"Władysław.Bożyk"
"Jakub.Nieć"
"Artur.Augustyn"
"Zdzisław.Wysocki"
"Edward.Skrzypkowski"
"Mieczysław.Strzałka"
"Damian.Flis"
"Dawid.Borowski"
"Przemysław.Juda"
"Sebastian.Gwiżdż"
"Czesław.Turski"
"Leszek.Kubicz"
"Karolina.Nędza"
"Bożena.Gawlak"
"Urszula.Babicka"
"Justyna.Miler"
"Renata.Lenczewska"
)

for i in "${names[@]}"; do
    $(curl -X POST http://localhost/v3/init -H "Host: testing.castle-api.castle.com" -H "X-Castle-Auth:oxGCE1Hypile7yys3sUJmlMOGXjcAswc:NQnR2jVQTOTHmmNcK9c6xWmDIc5dqq00" -H "x-app-inner-hash:$i" --data "app_version=v3&display_name=$i")
done
