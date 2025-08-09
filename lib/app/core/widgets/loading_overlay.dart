// -----------------------------------------------------------
// app/core/widgets/loading_overlay.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  const LoadingOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingService>(
      builder: (context, loadingService, _) {
        return Stack(
          children: [
            child,
            if (loadingService.isLoading)
              AbsorbPointer(
                child: Container(
                  color: const Color.fromARGB(166, 0, 0, 0),
                  child: const Center(
                    child: SpinKitWanderingCubes(
                      color: Colors.white,
                      size: 70.0,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}