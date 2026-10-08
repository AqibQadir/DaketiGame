import 'package:flutter/material.dart';
import '../../domain/models/game_reaction.dart';
import 'reaction_sticker.dart';

const _gold = Color(0xFFC58B43);
const _cream = Color(0xFFE9D1A0);

class ReactionPicker extends StatelessWidget {
  const ReactionPicker(
      {super.key, required this.onSelect, required this.onClose});
  final ValueChanged<GameReaction> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFA111E18),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _gold, width: 2)),
        elevation: 12,
        child: SizedBox(
            width: 290,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  const Expanded(
                      child: Text('MEHFIL KI BAATEIN',
                          style: TextStyle(
                              color: _cream,
                              fontWeight: FontWeight.w900,
                              fontSize: 12))),
                  SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                          tooltip: 'Close reactions',
                          padding: EdgeInsets.zero,
                          onPressed: onClose,
                          icon: const Icon(Icons.close,
                              color: _cream, size: 19))),
                ]),
                const SizedBox(height: 5),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final reaction in GameReaction.values)
                    SizedBox(
                        width: 130,
                        height: 67,
                        child: InkWell(
                          key: ValueKey('reaction-option-${reaction.name}'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => onSelect(reaction),
                          child: Ink(
                              decoration: BoxDecoration(
                                  color: const Color(0xFF24352A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _gold.withValues(alpha: .5))),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ReactionSticker(
                                        reaction: reaction, size: 32),
                                    const SizedBox(height: 3),
                                    Text(reaction.caption,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: _cream,
                                            fontSize: 10,
                                            height: 1.1,
                                            fontWeight: FontWeight.w700)),
                                  ])),
                        )),
                ]),
              ]),
            )),
      );
}

class PlayerReactionBubble extends StatelessWidget {
  const PlayerReactionBubble({super.key, required this.reaction});
  final GameReaction reaction;
  @override
  Widget build(BuildContext context) => IgnorePointer(
          child: Container(
        width: 154,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFA17251C),
            border: Border.all(color: _gold, width: 1.4),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)]),
        child: Row(children: [
          ReactionSticker(reaction: reaction, size: 26),
          const SizedBox(width: 5),
          Expanded(
              child: Text(reaction.caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _cream,
                      fontSize: 10,
                      height: 1.1,
                      fontWeight: FontWeight.w800))),
        ]),
      ));
}
