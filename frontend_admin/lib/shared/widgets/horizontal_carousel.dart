import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Carrusel horizontal estilo SaaS para tarjetas de contenido.
class HorizontalCarousel extends StatelessWidget {
  const HorizontalCarousel({
    super.key,
    required this.children,
    this.height = 148,
    this.emptyWidget,
    this.title,
    this.trailing,
  });

  final List<Widget> children;
  final double height;
  final Widget? emptyWidget;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        SizedBox(
          height: height,
          child: children.isEmpty
              ? (emptyWidget ?? const Center(child: Text('Sin registros')))
              : ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: children.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => children[i],
                  ),
                ),
        ),
      ],
    );
  }
}
