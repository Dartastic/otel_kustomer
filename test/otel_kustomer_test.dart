// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_kustomer/otel_kustomer.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_kustomer-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('conversations.create records channel + priority + queue', () async {
    await tracedKustomer<String>(
      operation: 'conversations.create',
      invoke: () async => const KustomerCallResult(
        value: 'ok',
        result: KustomerResult(
          channel: 'whatsapp',
          status: 'open',
          priority: 2,
          queueId: 'q-1',
          workflowRunId: 'wf-1',
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('kustomer conversations.create')!);
    expect(a['kustomer.channel'], 'whatsapp');
    expect(a['kustomer.conversation.priority'], 2);
    expect(a['kustomer.queue.id'], 'q-1');
    expect(a['kustomer.workflow.run_id'], 'wf-1');
  });

  test('suppression skips spans', () async {
    await runWithoutKustomerInstrumentationAsync(() async {
      await tracedKustomer<String>(
        operation: 'customers.list',
        invoke: () async => const KustomerCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('kustomer '), isEmpty);
  });
}
