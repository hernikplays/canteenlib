---
description: Jak začít s používáním API
---

# Quick Start

{% hint style="danger" %}
Využívání balíku je na vlastní nebezpečí, neručíme za škody způsobené používáním!
{% endhint %}

## Instalace balíku

Knihovna je hostována na [pub.dev](https://pub.dev/packages/canteenlib), instalace se provede jednoduše pomocí `dart pub add canteenlib`, pokud používáte Flutter pak `flutter pub add canteenlib`

## Vytvořit instanci

Základem je vytvoření instance třídy `Canteen`, která obsahuje všechny metody pro komunikaci s iCanteen. Jediný parametr této třídy je URL k vašemu kýženému iCanteen.

```dart
import 'package:canteenlib/canteenlib.dart';
// ...
Canteen c = Canteen("https://kantyna.neco.cz");
// ...
```

## Přihlášení

Přihlášení za váš účet provedete pomocí metody `login`, parametry jsou uživatelské jméno a heslo.

{% hint style="info" %}
Knihovna používá hlavně [asynchronní funkce](https://dart.dev/codelabs/async-await), které vrací Future, doporučujeme používat uvnitř jiné asynchronní funkce s `await`.
{% endhint %}

```dart
// ...
Canteen c = Canteen("https://kantyna.neco.cz");
var l = await c.login("jmeno","heslo")
```

Metoda vrací `bool` nebo chybu. Pokud se nelze přihlásit pomocí jména nebo hesla, vrací metoda `false`, v případě jiné chyby `Future.error` a při úspěšném přihlášení `true`.

## Dělejte co potřebujete

Nyní byste měli být připravení na to, abyste posílali ostatní požadavky. Prohlédněte si [referenci](broken-reference), [podrobnou dokumentaci](https://pub.dev/documentation/canteenlib/latest/canteenlib/canteenlib-library.html) nebo [příklady](reference/priklady.md) pro pomoc s pokračováním.
