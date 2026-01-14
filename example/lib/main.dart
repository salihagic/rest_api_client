import 'package:flutter/material.dart';
import 'package:rest_api_client/rest_api_client.dart';

/// Global API client instance
late RestApiClient apiClient;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage (required once per app lifetime)
  await RestApiClient.initFlutter();

  // Create and configure the API client
  apiClient = RestApiClientImpl(
    options: RestApiClientOptions(
      // Using JSONPlaceholder as a free test API
      baseUrl: 'https://jsonplaceholder.typicode.com',
      cacheEnabled: true,
    ),
    authOptions: AuthOptions(
      // Configure token refresh (example configuration)
      refreshTokenEndpoint: '/auth/refresh',
      resolveJwt: (response) => response.data['accessToken'],
      resolveRefreshToken: (response) => response.data['refreshToken'],
    ),
    loggingOptions: LoggingOptions(
      // Enable logging for debugging
      logNetworkTraffic: true,
    ),
    cacheOptions: CacheOptions(
      cacheLifetimeDuration: const Duration(minutes: 5),
      useAuthorization: false, // Public API, no auth needed
    ),
    retryOptions: RetryOptions(enabled: true, maxRetries: 3),
  );

  // Initialize the client
  await apiClient.init();

  // Listen to exceptions globally
  apiClient.exceptionHandler.exceptions.stream.listen((exception) {
    debugPrint('Global exception: $exception');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rest API Client Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rest API Client Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _ExampleTile(
            title: 'GET Request',
            subtitle: 'Fetch a list of posts',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GetExampleScreen()),
                ),
          ),
          _ExampleTile(
            title: 'POST Request',
            subtitle: 'Create a new post',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostExampleScreen()),
                ),
          ),
          _ExampleTile(
            title: 'Caching',
            subtitle: 'Cache-first and streamed requests',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CacheExampleScreen()),
                ),
          ),
          _ExampleTile(
            title: 'Error Handling',
            subtitle: 'Handle different error types',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ErrorExampleScreen()),
                ),
          ),
          _ExampleTile(
            title: 'Type Conversion',
            subtitle: 'Parse responses into typed objects',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TypedExampleScreen()),
                ),
          ),
        ],
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExampleTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// =============================================================================
// GET Request Example
// =============================================================================

class GetExampleScreen extends StatefulWidget {
  const GetExampleScreen({super.key});

  @override
  State<GetExampleScreen> createState() => _GetExampleScreenState();
}

class _GetExampleScreenState extends State<GetExampleScreen> {
  List<dynamic> posts = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    // Simple GET request
    final result = await apiClient.get(
      '/posts',
      queryParameters: {'_limit': 10},
    );

    setState(() {
      isLoading = false;
      if (result.hasData) {
        posts = result.data;
      } else if (result.isError) {
        error = result.exception.toString();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GET Request Example')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchPosts,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return ListTile(
          leading: CircleAvatar(child: Text('${post['id']}')),
          title: Text(
            post['title'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            post['body'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

// =============================================================================
// POST Request Example
// =============================================================================

class PostExampleScreen extends StatefulWidget {
  const PostExampleScreen({super.key});

  @override
  State<PostExampleScreen> createState() => _PostExampleScreenState();
}

class _PostExampleScreenState extends State<PostExampleScreen> {
  final titleController = TextEditingController(text: 'My New Post');
  final bodyController = TextEditingController(
    text: 'This is the post content.',
  );
  bool isLoading = false;
  Map<String, dynamic>? createdPost;

  Future<void> createPost() async {
    setState(() {
      isLoading = true;
      createdPost = null;
    });

    // POST request with data
    final result = await apiClient.post(
      '/posts',
      data: {
        'title': titleController.text,
        'body': bodyController.text,
        'userId': 1,
      },
    );

    setState(() {
      isLoading = false;
      if (result.hasData) {
        createdPost = result.data;
      }
    });

    if (mounted && result.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post created with ID: ${result.data['id']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POST Request Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : createPost,
              child:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Create Post'),
            ),
            if (createdPost != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Created Post:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${createdPost!['id']}'),
                      Text('Title: ${createdPost!['title']}'),
                      Text('Body: ${createdPost!['body']}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }
}

// =============================================================================
// Caching Example
// =============================================================================

class CacheExampleScreen extends StatefulWidget {
  const CacheExampleScreen({super.key});

  @override
  State<CacheExampleScreen> createState() => _CacheExampleScreenState();
}

class _CacheExampleScreenState extends State<CacheExampleScreen> {
  List<String> logs = [];
  bool isLoading = false;

  void addLog(String message) {
    setState(() {
      logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
  }

  Future<void> fetchWithCache() async {
    setState(() {
      logs.clear();
      isLoading = true;
    });

    addLog('Starting getCachedOrNetwork request...');

    // Cache-first strategy: returns cached data if available, otherwise fetches from network
    final result = await apiClient.getCachedOrNetwork('/posts/1');

    if (result.hasData) {
      final source = result is CacheResult ? 'CACHE' : 'NETWORK';
      addLog('Got data from $source: ${result.data['title']}');
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchStreamed() async {
    setState(() {
      logs.clear();
      isLoading = true;
    });

    addLog('Starting getStreamed request...');

    // Stale-while-revalidate: emits cached data first, then fresh data
    await for (final result in apiClient.getStreamed('/posts/2')) {
      if (result.hasData) {
        final source = result is CacheResult ? 'CACHE' : 'NETWORK';
        addLog('Got data from $source: ${result.data['title']}');
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchCacheOnly() async {
    setState(() {
      logs.clear();
    });

    addLog('Fetching from cache only...');

    // Cache-only: returns only cached data, no network request
    final result = await apiClient.getCached('/posts/1');

    if (result.hasData) {
      addLog('Found in cache: ${result.data['title']}');
    } else {
      addLog('Not found in cache');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caching Example')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : fetchWithCache,
                  child: const Text('Cache or Network'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : fetchStreamed,
                  child: const Text('Streamed'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : fetchCacheOnly,
                  child: const Text('Cache Only'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return Text(
                  logs[index],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Error Handling Example
// =============================================================================

class ErrorExampleScreen extends StatefulWidget {
  const ErrorExampleScreen({super.key});

  @override
  State<ErrorExampleScreen> createState() => _ErrorExampleScreenState();
}

class _ErrorExampleScreenState extends State<ErrorExampleScreen> {
  String? resultText;
  bool isLoading = false;

  Future<void> triggerNotFound() async {
    setState(() {
      isLoading = true;
      resultText = null;
    });

    // Request to a non-existent endpoint
    final result = await apiClient.get('/posts/99999999');

    setState(() {
      isLoading = false;
      if (result.isError) {
        if (result.exception is ValidationException) {
          resultText = 'ValidationException: Resource not found (404)';
        } else {
          resultText = 'Error: ${result.exception}';
        }
        resultText = '$resultText\nStatus: ${result.statusCode}';
      } else {
        resultText = 'Unexpected success: ${result.data}';
      }
    });
  }

  Future<void> handleResultSafely() async {
    setState(() {
      isLoading = true;
      resultText = null;
    });

    final result = await apiClient.get('/posts/1');

    setState(() {
      isLoading = false;

      final buffer = StringBuffer();

      // Check various result properties
      buffer.writeln('hasData: ${result.hasData}');
      buffer.writeln('isSuccess: ${result.isSuccess}');
      buffer.writeln('isError: ${result.isError}');
      buffer.writeln('isConnectionError: ${result.isConnectionError}');
      buffer.writeln('statusCode: ${result.statusCode}');

      if (result.hasData) {
        buffer.writeln('\nData: ${result.data['title']}');
      }

      resultText = buffer.toString();
    });
  }

  Future<void> silentRequest() async {
    setState(() {
      isLoading = true;
      resultText = null;
    });

    // Silent exception: won't broadcast to global exception stream
    final result = await apiClient.get(
      '/invalid-endpoint',
      options: RestApiClientRequestOptions(silentException: true),
    );

    setState(() {
      isLoading = false;
      resultText =
          result.isError
              ? 'Silent error (not broadcast globally): ${result.exception}'
              : 'Success: ${result.data}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Handling Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : triggerNotFound,
                  child: const Text('Trigger 404'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : handleResultSafely,
                  child: const Text('Check Result'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : silentRequest,
                  child: const Text('Silent Error'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (resultText != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    resultText!,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Type Conversion Example
// =============================================================================

/// Example model class
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      body: json['body'],
    );
  }
}

class TypedExampleScreen extends StatefulWidget {
  const TypedExampleScreen({super.key});

  @override
  State<TypedExampleScreen> createState() => _TypedExampleScreenState();
}

class _TypedExampleScreenState extends State<TypedExampleScreen> {
  Post? post;
  List<Post>? posts;
  bool isLoading = false;

  Future<void> fetchSinglePost() async {
    setState(() {
      isLoading = true;
      post = null;
      posts = null;
    });

    // Use onSuccess to parse response into typed object
    final result = await apiClient.get<Post>(
      '/posts/1',
      onSuccess: (data) => Post.fromJson(data),
    );

    setState(() {
      isLoading = false;
      if (result.hasData) {
        post = result.data;
      }
    });
  }

  Future<void> fetchPostList() async {
    setState(() {
      isLoading = true;
      post = null;
      posts = null;
    });

    // Parse list response
    final result = await apiClient.get<List<Post>>(
      '/posts',
      queryParameters: {'_limit': 5},
      onSuccess: (data) => (data as List).map((e) => Post.fromJson(e)).toList(),
    );

    setState(() {
      isLoading = false;
      if (result.hasData) {
        posts = result.data;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Type Conversion Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : fetchSinglePost,
                    child: const Text('Fetch Single'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : fetchPostList,
                    child: const Text('Fetch List'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (post != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post (typed)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${post!.id}'),
                      Text('User ID: ${post!.userId}'),
                      Text('Title: ${post!.title}'),
                      Text(
                        'Body: ${post!.body}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              )
            else if (posts != null)
              Expanded(
                child: ListView.builder(
                  itemCount: posts!.length,
                  itemBuilder: (context, index) {
                    final p = posts![index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${p.id}')),
                        title: Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('User: ${p.userId}'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
