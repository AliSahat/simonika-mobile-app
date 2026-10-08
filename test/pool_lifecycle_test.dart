import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simonika_mobile_app/screens/pool/update_pool_screen.dart';

void main() {
  testWidgets('Regression test: close page while fetch is ongoing', (tester) async {
    SharedPreferences.setMockInitialValues({'token': 'dummy_token'});
    
    // Create a Dio client that never completes its request
    final mockDio = Dio();
    mockDio.httpClientAdapter = _MockHttpClientAdapter();
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(arguments: 'pool-123'),
                  builder: (_) => UpdatePoolScreen(client: mockDio),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));
    
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    
    // Page is open and fetching. Close it.
    await tester.pageBack();
    await tester.pumpAndSettle();
    
    expect(find.byType(UpdatePoolScreen), findsNothing);
    // If it doesn't crash here or later when the request is cancelled, it passes.
  });
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    // Wait indefinitely to simulate an ongoing request, but support cancellation
    final completer = Future<ResponseBody>.delayed(const Duration(hours: 1), () => ResponseBody.fromString('', 200));
    if (cancelFuture != null) {
      cancelFuture.then((_) {
        // Handle cancel
      });
    }
    return completer;
  }
  
  @override
  void close({bool force = false}) {}
}
