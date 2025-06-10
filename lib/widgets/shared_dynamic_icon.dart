import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SharedDynamicIcon extends StatelessWidget {
  final Color? color;
  final double height;
  final dynamic path;
  final double? fill;
  final double? weight;

  const SharedDynamicIcon(this.path, {super.key, this.color, this.height = 16, this.fill, this.weight});

  @override
  Widget build(BuildContext context) {
    return path is String && path.toString().endsWith('.svg')
        ? SvgPicture.asset(
            path,
            height: height,
            colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
          )
        : path is String && path.toString().endsWith('.png')
            ? Image.asset(
                path,
                height: height,
              )
            : Icon(
                path,
                size: height,
                color: color,
                weight: weight,
                fill: fill,
              );
  }
}
