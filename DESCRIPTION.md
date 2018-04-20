# StoredProcedures

Plik opisujący załączone procedury. W bazie danych każda z tych procedur jest utworzona w odrębnym schemacie, agregującym encje z wybranego modułu aplikacji w celu łatwiejszego nadawania uprawnień oraz przejrzystości bazy. 
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
#createClient

1. Procedura tworząca nowego klienta w bazie.
2. Przyjmuje argument XML
3. Zawira blok try oraz catch w razie niepowodzenia operacji wszystko zostaje cofnięte do stanu sprzed wywołania procedury
4. Za pomocą jednej procedury robię INSERT do czterech tabel 


Zarys działania
W bazie została utowrzona tabela GeneralDetails w celu przechowywania wspólnych danych dla wielu Encji oraz w celu możliwości przechowywania, np. wielu adresów oraz kontaktów danego klienta. Dzięki takiemu rozwiązaniu nie musiałam duplikować tabel oraz podczas pisania zapytań nie miałam problemu z wyciągnięciem potrzebnych danych.

Kolumna SHA256 - Jest generowana automatycznie na poziomie API przed wysłaniem do bazy, cel tej kolumny jest taki, że podczas pracy z plikiem XML oraz insertem do wielu tabel potrzebna jest kolumna unikalna predefiniowana, nie może to być GUID wiersza, ponieważ jest on nadawany podczas insertu, a ja potrzebowałam unikalnej wartości przed operacją INSERT w celu relacyjnego powiązania wszystkich tabel w trakcie jednego wywołania procedury. 


Przykład wykorzystania właściwości tej tabeli jest w linii 37.
(Select Id from person.GeneralDetails where Sha256 = m.value('../GeneralDetails[1]/Sha256[1]', 'nvarchar(300)')) as hashsha256,
	m.value('UserName[1]', 'nvarchar(50)') as username
  
Wiążemy tabele na podstawie relacji za pomocą kodu SHA256 i wybieramy ID potrzebnego wiersza. Dzięki temu mamy poprawnie powiązane tabele w bazie oraz mamy możliwośc INSERTU do wielu tabel bez względu na złożonośc dokumentu XML oraz jego zagnieżdżenia. 

Nastepuje COMMIT TRAN, czyli zatwierdzenie transakcji i wszystkie dane zostają umieszczone w bazie.

W bloku CATCH sprawdzamy wartość @@TRANCOUNT, cofamy wszystkie zmiany wywołane przez procedurę oraz wyrzucamy błąd do API

----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

#getClassification

1. Procedura pobierająca wszystkie faktury danego klienta
2. Przyjmuje jeden argument NVARCHAR 
3. Po wykonaniu procedury otrzymujemy zagnieżdżony plik JSON

Zarys działania
Procedura przyjmuje jako argument Id klienta, dla którego ma być zwrócona kolekcja utworzonych przez niego klasyfikacji, które z kolei mają zagnieżdżone w sobie reguły, a reguły z kolei mają zagnieżdżone tagi. Przykładowy plik JSON wygenerowany dzięki procedurze można zobaczyć jako plik ExampleClassification.json, niektóre klasyfikacje mogą nie mieć przypisanych reguł. 

W procedurze można dowolnie modyfikować czyli dodawać bądź usuwać zestaw zwracanych danych. 

-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------

-- updateInvoice

1. Procedura przyjmuje argument XML
2. Za pomocą procedury jesteśmy w stanie przeprowadzić aktualizację łącznie na siedmiu tabelach, wszystkich tych.

Zarys działania
Procedura ma na celu zaktualizowanie danych, które zostały zeskanowane przez system OCR, przykładowy plik XML wysyłany za pomocą API można zobaczyć w repozytorium jako exampleXMLforUpdateInvoice. 

Zakładając, że 5 lat temu kontraktor  A miał adres X. Dowiadujemy się, że od dnia jutrzejszego wszystkie faktury jakie nasza firma będzie dostawac, będą z nowym adresem B. Taka sytuacja, wymysza zachowywanie danych historycznych na starszych fakturach oraz dodawanie nowych faktur z nowym adresem, w ty celu została stworzona tabela funkcyjna Invoices_Addresses przechowująca klucze zatwierdzonych faktur oraz adresów. Dzięki temu faktury sprzed 4 lat nie zmienią nagle starego adresu kontraktora na nowy za sprawą operacji UPDATE, ponieważ jesteśmy w stanie wskazać adres który powinien być zaktualizowany. 
