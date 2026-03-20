import 'package:flutter/material.dart';

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
}
