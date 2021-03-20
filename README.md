# Storage repository
Abstraction for persisting and reading data to platform specific storage.
You can also find this package on pub as [rest_api_client](https://pub.dev/packages/rest_api_client) 

## Usage
```
Future main() async {
    WidgetsFlutterBinding.ensureInitialized();

    //Instantiate a basic storage repository
    IStorageRepository storageRepository = StorageRepository();
    //or use a secure version of storage repository
    storageRepository = SecureStorageRepository();
    //init must be called, preferably right after the instantiation
    await storageRepository.init();

    await storageRepository.set('some_string_key', 'Some string');
    await storageRepository.set('some_int_key', 0);
    //dynamic keys are also possible
    await storageRepository.set(1, 1);

    //result: Some string (dynamic)
    print(await storageRepository.get('some_string_key'));

    //result: 0 (dynamic)
    print(await storageRepository.get('some_int_key'));

    //result: 1 (dynamic)
    print(await storageRepository.get(1));

    //result: 1 (int?)
    print(await storageRepository.get<int>(1));

    await storageRepository.delete('some_string_key');

    await storageRepository.print();

    await storageRepository.clear();
}

```