import 'package:flutter/material.dart';
import '../core/theme.dart';

class Player {
  final String id;           // UUID, generated at touch-down
  final int pointerId;       // Flutter PointerEvent.pointer — OS touch identifier
  final Color color;         // assigned from RaakColors.playerColor(arrivalIndex)
  final String nickname;     // "P1", "P2", etc. — editable post-round
  final int arrivalIndex;    // 0-based order finger landed — used by Chaos Control
  final Offset position;     // last known screen position

  const Player({
    required this.id,
    required this.pointerId,
    required this.color,
    required this.nickname,
    required this.arrivalIndex,
    required this.position,
  });

  Player copyWith({
    String? nickname,
    Offset? position,
  }) => Player(
    id: id,
    pointerId: pointerId,
    color: color,
    nickname: nickname ?? this.nickname,
    arrivalIndex: arrivalIndex,
    position: position ?? this.position,
  );

  Map<String, dynamic> toHistoryJson() => {
    'arrivalIndex': arrivalIndex,
    'nickname': nickname,
  };

  factory Player.fromHistoryJson(Map<String, dynamic> j) => Player(
    id: 'restored_${j['arrivalIndex']}',
    pointerId: 0,
    color: RaakColors.playerColor(j['arrivalIndex'] as int),
    nickname: j['nickname'] as String,
    arrivalIndex: j['arrivalIndex'] as int,
    position: Offset.zero,
  );
}
