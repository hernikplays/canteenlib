## INFO
__Knihovna již není aktivně vyvíjena a jsou vydávány pouze rychlé opravy, když je potřebuji. Pokud někdo chcete moji hroznou práci přebrat nebo chcete zde mít odkaz na vaši vlastní implementaci, dejte mi vědět.__

## O knihovně
Experimentální **neoficiální** webscrape knihovna pro komunikaci se systémem [iCanteen](https://www.z-ware.cz/internetove-objednavky). **Knihovna je aktuálně nestabilní! Používejte na vlastní riziko!**

[![wakatime](https://wakatime.com/badge/user/17178fab-a33c-430f-a764-7b3f26c7b966/project/82873d93-5b79-4978-a5f6-612e21641817.svg)](https://wakatime.com/badge/user/17178fab-a33c-430f-a764-7b3f26c7b966/project/82873d93-5b79-4978-a5f6-612e21641817) [![Pub Version (including pre-releases)](https://img.shields.io/pub/v/canteenlib?color=lightblue&include_prereleases&label=latest%20version)](https://pub.dev/packages/canteenlib)

## Funkční funkce(*)
- získání jídelníčku na aktuální den (s cenami)
- Objednání / zrušení objednávek
- Nabídnutí jídla do burzy / zrušení
- Získání a objednání cizího jídla z burzy

## To do
- Kompatibilita se staršími verzemi iCanteen

Příklad používání [zde](https://git.mnau.xyz/hernik/canteenlib/src/branch/main/example/canteenlib_example.dart)

*\* Knihovna nemusí fungovat na všech instancích systému iCanteen, proto žádám každého, kdo může a je uživatelem iCanteen, aby otestoval funkčnost této knihovny a případné problémy [nahlásil](https://git.mnau.xyz/hernik/canteenlib/issues/new)*

### Otestované instance iCanteen
[zde](https://git.mnau.xyz/hernik/canteenlib/src/branch/main/COMPATIBILITY.md)

## Licence
```
MIT License

Copyright (c) 2022 Matyáš Caras

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```