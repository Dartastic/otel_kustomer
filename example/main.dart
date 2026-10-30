// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_kustomer/otel_kustomer.dart';

/// Traces Kustomer calls with OpenTelemetry.
///
/// `otel_kustomer` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Kustomer call in
/// [tracedKustomer]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'kustomer-example');

  // Wraps a Kustomer API call in a CLIENT span.
  final kustomerId = await tracedKustomer<String>(
    operation: 'customers.create',
    invoke: () async {
      // Make the Kustomer call here, then report what it returned.
      const id = 'kustomer_8f3a2c';
      return const KustomerCallResult(
          value: id,
          result: KustomerResult(
              itemCount: 3,
              total: 1,
              channel: 'email',
              status: 'open',
              priority: 1,
              queueId: 'queue_8f3a2c',
              workflowRunId: 'workflowrun_8f3a2c',
              satisfactionScore: 1,
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedKustomer customers.create returned $kustomerId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutKustomerInstrumentationAsync.
  await runWithoutKustomerInstrumentationAsync(
    () => tracedKustomer<String>(
      operation: 'customers.create',
      invoke: () async {
        const id = 'kustomer_8f3a2c';
        return const KustomerCallResult(
            value: id,
            result: KustomerResult(
                itemCount: 3,
                total: 1,
                channel: 'email',
                status: 'open',
                priority: 1,
                queueId: 'queue_8f3a2c',
                workflowRunId: 'workflowrun_8f3a2c',
                satisfactionScore: 1,
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
