import 'package:canteenlib/canteenlib.dart';

void main() {
  var canteen = Canteen("http://icanteen.vasedomena.neco");
  canteen.login("user", "password").then((_) {
    canteen.jidelnicekDen().then((jidelnicek) {
      print(jidelnicek.jidla[0].hlavni);
    });
  });
}
