import 'package:flutter/material.dart';

/// Cards float directly on the screen; the centered selection grows smoothly
/// while its neighbors remain visible to make horizontal browsing apparent.
class FocusedCardCarousel extends StatefulWidget {
  const FocusedCardCarousel(
      {super.key,
      required this.itemCount,
      required this.itemBuilder,
      required this.pageKey,
      required this.label});
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Key pageKey;
  final String label;

  @override
  State<FocusedCardCarousel> createState() => _FocusedCardCarouselState();
}

class _FocusedCardCarouselState extends State<FocusedCardCarousel> {
  late final PageController _controller;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    // Start far inside a repeating strip so the first card has neighbors on
    // both sides immediately, without changing the logical city/tier order.
    _controller = PageController(
      viewportFraction: .23,
      initialPage: widget.itemCount * 1000,
    );
  }

  void _go(int index) {
    final current = _controller.page?.round() ?? _controller.initialPage;
    var delta = index - _selected;
    if (delta > widget.itemCount / 2) delta -= widget.itemCount;
    if (delta < -widget.itemCount / 2) delta += widget.itemCount;
    _controller.animateToPage(current + delta,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
            child: PageView.builder(
          key: widget.pageKey,
          controller: _controller,
          onPageChanged: (index) =>
              setState(() => _selected = index % widget.itemCount),
          itemBuilder: (context, index) => AnimatedBuilder(
            animation: _controller,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: widget.itemBuilder(context, index % widget.itemCount)),
            builder: (context, child) {
              final page =
                  _controller.hasClients && _controller.position.haveDimensions
                      ? _controller.page ?? 0
                      : _controller.initialPage.toDouble();
              final distance = (page - index).abs().clamp(0.0, 1.0);
              return Transform(
                key: ValueKey(
                    '${widget.label}-scale-${index % widget.itemCount}'),
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                    1 - .04 * distance, 1 - .16 * distance, 1),
                child: CardCarouselSelection(
                  selected: index == page.round(),
                  child: child!,
                ),
              );
            },
          ),
        )),
        SizedBox(
            height: 24,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(widget.label.toUpperCase(),
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFFE9D1A0))),
              const SizedBox(width: 8),
              for (var i = 0; i < widget.itemCount; i++)
                Semantics(
                    button: true,
                    selected: i == _selected,
                    label: '${widget.label} ${i + 1}',
                    child: InkWell(
                        onTap: () => _go(i),
                        child: SizedBox(
                            width: 16,
                            height: 24,
                            child: Center(
                                child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    width: i == _selected ? 12 : 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                        color: i == _selected
                                            ? const Color(0xFFFF9800)
                                            : Colors.white54,
                                        borderRadius:
                                            BorderRadius.circular(5))))))),
              const SizedBox(width: 8),
              Text('${_selected + 1} / ${widget.itemCount}',
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFFE9D1A0))),
            ])),
      ]);
}

/// Selection belongs to a visible carousel position, including repeated cards.
class CardCarouselSelection extends InheritedWidget {
  const CardCarouselSelection(
      {super.key, required this.selected, required super.child});
  final bool selected;
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CardCarouselSelection>()
          ?.selected ??
      false;
  @override
  bool updateShouldNotify(CardCarouselSelection oldWidget) =>
      selected != oldWidget.selected;
}
