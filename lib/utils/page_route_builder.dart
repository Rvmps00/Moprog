import 'package:flutter/material.dart';

PageRouteBuilder pageRouteBuilder(WidgetBuilder builder) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionDuration: const Duration(milliseconds: 333),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var scaleTween = Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(slideTween),
        child: ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          ),
        ),
      );
    },
  );
}
