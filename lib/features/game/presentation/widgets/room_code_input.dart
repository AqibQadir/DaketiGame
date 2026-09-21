import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One editable value preserves native paste, selection and backspace behavior;
/// the four boxes are its visual representation, not separate text fields.
class RoomCodeInput extends StatefulWidget {
  const RoomCodeInput(
      {super.key,
      required this.controller,
      this.enabled = true,
      this.onSubmitted});
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  State<RoomCodeInput> createState() => _RoomCodeInputState();
}

class _RoomCodeInputState extends State<RoomCodeInput> {
  final focus = FocusNode();
  @override
  void initState() {
    super.initState();
    focus.addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant RoomCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;
    final active = (widget.controller.selection.baseOffset < 0
            ? value.length
            : widget.controller.selection.baseOffset)
        .clamp(0, 3);
    return SizedBox(
        height: 60,
        child: Stack(children: [
          Positioned.fill(
              child: ExcludeSemantics(
                  child: Row(children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                  child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF211C17),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: focus.hasFocus && i == active
                          ? const Color(0xFFFF8500)
                          : const Color(0xFF756B60),
                      width: focus.hasFocus && i == active ? 2 : 1),
                ),
                child: Text(
                    i < value.length
                        ? value[i]
                        : focus.hasFocus && i == active
                            ? '│'
                            : '',
                    style: TextStyle(
                        fontSize: 27,
                        color: i < value.length
                            ? Colors.white
                            : const Color(0xFFFF8500))),
              )),
            ],
          ]))),
          Positioned.fill(
              child: TextField(
            controller: widget.controller,
            focusNode: focus,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4)
            ],
            onSubmitted: widget.onSubmitted,
            showCursor: false,
            enableInteractiveSelection: true,
            style: const TextStyle(color: Colors.transparent, fontSize: 27),
            decoration: const InputDecoration(
                labelText: null,
                hintText: 'Room code',
                hintStyle: TextStyle(color: Colors.transparent),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 12)),
          )),
        ]));
  }
}
