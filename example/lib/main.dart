import 'package:flutter/material.dart';
import 'package:rest_api_client/rest_api_client.dart';
import 'package:storage_repository/storage_repository.dart';

const KEY = 'COUNTER_VALUE';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageRepository = StorageRepository();
  //or
  //final storageRepository = SecureStorageRepository();
  await storageRepository.init();

  runApp(
    MaterialApp(
      title: 'Storage repository example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Home(storageRepository: storageRepository),
    ),
  );
}

class Home extends StatefulWidget {
  final IStorageRepository storageRepository;

  Home({required this.storageRepository});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentValue = 0;

  @override
  void initState() {
    super.initState();
    widget.storageRepository.clear();
  }

  Future<int> getCurrentValue() async {
    return await widget.storageRepository.get<int>(KEY) ?? 0;
  }

  Future setNewValue(int value) async {
    await widget.storageRepository.set(KEY, value);
  }

  Future onPressed() async {
    var currentValue = await getCurrentValue();
    await setNewValue(currentValue + 1);
    _currentValue = await getCurrentValue();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Storage repository counter'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You have clicked increment button this many times:'),
            Text(
              _currentValue.toString(),
              style: TextStyle(fontSize: 26.0),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onPressed,
        child: Icon(Icons.add),
      ),
    );
  }
}
