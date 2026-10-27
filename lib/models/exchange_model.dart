enum ExchangeStatus { pending, completed, cancelled }

/// Model: the handover between a donor and the requester they selected.
/// It completes only once both parties have confirmed the handover.
class ExchangeModel {
  final String id;
  final String? itemPostId;
  final String? requestId;
  final String donorId;
  final String requesterId;
  final ExchangeStatus status;
  final DateTime? donorConfirmedAt;
  final DateTime? requesterConfirmedAt;

  const ExchangeModel({
    required this.id,
    this.itemPostId,
    this.requestId,
    required this.donorId,
    required this.requesterId,
    this.status = ExchangeStatus.pending,
    this.donorConfirmedAt,
    this.requesterConfirmedAt,
  });

  bool get isCompleted => status == ExchangeStatus.completed;

  bool hasConfirmed(String userId) => userId == donorId
      ? donorConfirmedAt != null
      : userId == requesterId && requesterConfirmedAt != null;

  ExchangeModel copyWith({
    ExchangeStatus? status,
    DateTime? donorConfirmedAt,
    DateTime? requesterConfirmedAt,
  }) {
    return ExchangeModel(
      id: id,
      itemPostId: itemPostId,
      requestId: requestId,
      donorId: donorId,
      requesterId: requesterId,
      status: status ?? this.status,
      donorConfirmedAt: donorConfirmedAt ?? this.donorConfirmedAt,
      requesterConfirmedAt: requesterConfirmedAt ?? this.requesterConfirmedAt,
    );
  }
}
