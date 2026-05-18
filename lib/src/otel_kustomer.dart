// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_kustomer_suppression.dart';

const _tracerName = 'dartastic_otel_libs_kustomer';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class KustomerResult {
  const KustomerResult({
    this.itemCount,
    this.total,
    this.channel,
    this.status,
    this.priority,
    this.queueId,
    this.workflowRunId,
    this.satisfactionScore,
    this.requestId,
    this.statusCode,
  });

  /// Items returned.
  final int? itemCount;

  /// `meta.total`.
  final int? total;

  /// `email` / `chat` / `sms` / `voice` / `kustomerVoice` / `instagram`
  /// / `facebook` / `whatsapp` / `kakao` / `forms`.
  final String? channel;

  /// `open` / `snoozed` / `done` / `merged`.
  final String? status;

  /// 1 (high) / 2 / 3 / 4 / 5 (low).
  final int? priority;

  /// Queue id (Kustomer's routing primitive).
  final String? queueId;

  /// Workflow run id when this call was triggered by automation.
  final String? workflowRunId;

  /// Most recent CSAT score for this conversation (1-5).
  final int? satisfactionScore;

  /// `X-Kustomer-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class KustomerCallResult<T> {
  const KustomerCallResult({required this.value, this.result});
  final T value;
  final KustomerResult? result;
}

/// Wraps a Kustomer API call in a CLIENT span. [operation] is one of
/// `customers.list`, `customers.get`, `customers.create`,
/// `customers.merge`, `conversations.list`, `conversations.get`,
/// `conversations.create`, `conversations.update`,
/// `messages.list`, `messages.create`, `notes.create`,
/// `workflows.list`, `workflows.run`, `queues.list`, `teams.list`,
/// `users.list`, `klasses.search`, `webhooks.create`.
Future<T> tracedKustomer<T>({
  required String operation,
  required Future<KustomerCallResult<T>> Function() invoke,
}) async {
  if (kustomerInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'kustomer',
    'rpc.method': operation,
    'kustomer.operation': operation,
  };

  final span = _tracer().startSpan(
    'kustomer $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'kustomer.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.total != null) {
        extras.add(OTel.attributeInt(
          'kustomer.total',
          r.result!.total!,
        ));
      }
      if (r.result!.channel != null) {
        extras.add(OTel.attributeString(
          'kustomer.channel',
          r.result!.channel!,
        ));
      }
      if (r.result!.status != null) {
        extras.add(OTel.attributeString(
          'kustomer.conversation.status',
          r.result!.status!,
        ));
      }
      if (r.result!.priority != null) {
        extras.add(OTel.attributeInt(
          'kustomer.conversation.priority',
          r.result!.priority!,
        ));
      }
      if (r.result!.queueId != null) {
        extras.add(OTel.attributeString(
          'kustomer.queue.id',
          r.result!.queueId!,
        ));
      }
      if (r.result!.workflowRunId != null) {
        extras.add(OTel.attributeString(
          'kustomer.workflow.run_id',
          r.result!.workflowRunId!,
        ));
      }
      if (r.result!.satisfactionScore != null) {
        extras.add(OTel.attributeInt(
          'kustomer.satisfaction.score',
          r.result!.satisfactionScore!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'kustomer.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Kustomer HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
