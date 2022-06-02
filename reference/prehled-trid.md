# Přehled tříd

Zde jsou zdokumentované všechny třídy, které lze uvnitř knihovny najít.

## Burza
Reprezentuje jedno jídlo na burze, které není vaše, respektive uživatele, který je přihlášený.

### Vlastnosti
#### den
[`DateTime`](https://api.dart.dev/stable/2.17.1/dart-core/DateTime-class.html) - Den, který je jídlo vydáváno
#### nazev
`String` - Název jídla
#### pocet
`int` - Počet kusů tohoto jídla v burze
#### url
`String?` - URL pro objednání jídla
#### varianta
`String?` - Druh varianty

## Canteen
Reprezentuje kantýnu / instanci iCanteen. 
Slouží pro uchovávání metod, pomocí kterých se komunikuje s instancí.

### Vlastnosti
#### cookies
[`Map`](https://api.dart.dev/stable/2.17.1/dart-core/Map-class.html)`<String, String>` - Obsahuje všechny sušenky, které jsou vyžadovany pro úspěšnou komunikaci, např. pro identifikaci uživatele
#### prihlasen
`bool` - Slouží k informování, zda-li je uživatel přihlášen
#### url
`String` - URL adresa instance kantýny
### Metody
{% hint style="danger" %}
Všechny metody vrací Future, pro získání hodnoty je nutné použít `.then` nebo `await`.
{% endhint %}

#### doBurzy
Slouží pro uložení jídla uživatele do burzy
##### Parametry
- [`Jidlo`](#jidlo) - Jídlo uživatele, které chce přesunout do burzy
##### Vrací
- [`Jidlo`](#jidlo) - Původní instance upravená o změněné parametry
#### jidelnicekDen
Slouží pro získání jídelníčku pro určitý den
##### Parametry
- `den` - [`DateTime`](https://api.dart.dev/stable/2.17.1/dart-core/DateTime-class.html)`?` *(volitelný)* - určuje pro který den chceme získat jídelníček; není-li zadán, je použito dnešní datum
##### Vrací
- [`Jidelnicek`](#jidelnicek) - Jídelníček pro daný den
#### login
Slouží pro autorizaci a přihlášení uživatele
##### Parametry
- `String` - uživatelské jméno
- `String` - heslo
##### Vrací
- `bool` - `true` v případě přihlášení, jinak `false`
#### objednat
Objedná jídlo zadané v parametru
##### Parametry
- [`Jidlo`](#jidlo) - Jídlo, které chce uživatel objednat
##### Vrací
- [`Jidlo`](#jidlo) - Instance upravená o změněné parametry
#### objednatZBurzy
Objedná jídlo z burzy uvedené v parametru
##### Parametry
- [`Burza`](#burza) - Cizí jídlo z burzy, které chce uživatel objednat
##### Vrací
- `bool` - `true` v případě, že bylo jídlo úspěšně objednáno
#### ziskatBurzu
Získá aktuální jídla v burze, která může uživatel objednat. (iCanteen ve výchozím stavu nezobrazuje jídla v burze pro dny, kdy má uživatel objednáno)
##### Vrací
- [`List`](https://api.dart.dev/stable/2.17.1/dart-core/List-class.html)[`Burza`](#burza) - Seznam jídel v burze
#### ziskejJidelnicek
Získá aktuální holý jídelníček (více dnů), jelikož bere z hlavní stránky, **není nutné přihlášení**
##### Vrací
- [`List`](https://api.dart.dev/stable/2.17.1/dart-core/List-class.html)[`Jidelnicek`](#jidelnicek) - Jídelníčky pro dny, které jsou zobrazené na hlavní stránce
#### ziskejUzivatele
Vrátí údaje o uživateli
##### Vrací
- [`Uzivatel`](#uzivatel) - Instance třídy obsahující všechny údaje, jsou-li vyplněné

## Jidelnicek
Třídá reprezentující jídelníček pro určitý den v týdnu
### Vlastnosti
#### 
#### den
[`DateTime`](https://api.dart.dev/stable/2.17.1/dart-core/DateTime-class.html) - Den, pro který jídelníček platí
#### jidla
[`List`](https://api.dart.dev/stable/2.17.1/dart-core/List-class.html)[`Jidlo`](#jidlo) - Seznam jídel v tomto jídelníčku

## Jidlo
Reprezentuje jedno určité jídlo v jídelníčku
### Vlastnosti
#### burzaUrl
`String?` - URL pro vložení jídla na burzu, je-li už objednáno
#### cena
`double` - Cena za jídlo
#### den
[`DateTime`](https://api.dart.dev/stable/2.17.1/dart-core/DateTime-class.html) - Den, který je jídlo vydáváno
#### lzeObjednat
`bool` - Udává, zda-li jde jídlo objednat
#### naBurze
`bool` - Udává, zda-li je jídlo aktuálně na burze
#### nazev
`String` - Název jídla
#### objednano
`bool` - Udává, zda-li si uživatel jídlo objednal nebo ne
#### orderUrl
`String?` - URL pro objednání/zrušení objednání jídla
#### varianta
`String` - Název varianty

## Uzivatel
Uchovává informace o přihlášeném uživateli
### Vlastnosti
#### jmeno
`String?` - Jméno, jak je uvedené v základních údajích o uživateli 
#### kategorie
`String?` - Kategorie uživatele
#### Kredit
`double` - Aktuální stav kreditu
#### prijmeni
`String?` Příjmení, jak je uvedené v základních údajích o uživateli 
#### specSymbol
`String?` - Specifický symbol
#### ucetProPlatby
`String?` - Účet jídelny pro zasílání plateb
#### uzivatelskeJmeno
`String?` - Uživatelské jméno
#### varSymbol
`String?` - Variabilní symbol
