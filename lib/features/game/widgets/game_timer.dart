import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GameTimer extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback onTimerEnd;
  final bool isFrozen;
  final int? frozenSecondsRemaining;
  final Function(int)? onTick;

  const GameTimer({
    super.key,
    required this.totalSeconds,
    required this.onTimerEnd,
    this.isFrozen = false,
    this.frozenSecondsRemaining,
    this.onTick,
  });

  @override
  State<GameTimer> createState() => GameTimerState();
}

class GameTimerState extends State<GameTimer> with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isClutchMode = false;

  int get remainingSeconds => _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalSeconds;
    _startTimer();
  }

  @override
  void didUpdateWidget(GameTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFrozen != oldWidget.isFrozen) {
      if (widget.isFrozen) {
        _pauseTimer();
      } else {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0 && !widget.isFrozen) {
        setState(() {
          _remainingSeconds--;
          _isClutchMode = _remainingSeconds <= 10;
        });
        widget.onTick?.call(_remainingSeconds);
      } else if (_remainingSeconds <= 0) {
        timer.cancel();
        widget.onTimerEnd();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void addTime(int seconds) {
    setState(() {
      _remainingSeconds += seconds;
    });
  }

  void reset() {
    setState(() {
      _remainingSeconds = widget.totalSeconds;
      _isClutchMode = false;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    Color timerColor;
    if (widget.isFrozen) {
      timerColor = Colors.lightBlue;
    } else if (_isClutchMode) {
      timerColor = Colors.red;
    } else if (_remainingSeconds <= 30) {
      timerColor = Colors.orange;
    } else {
      timerColor = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: timerColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isFrozen)
            const Icon(Icons.ac_unit, color: Colors.lightBlue, size: 18)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1000.ms)
          else
            Icon(Icons.timer, color: timerColor, size: 18),
          const SizedBox(width: 6),
          Text(
            timeString,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: timerColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ).animate(target: _isClutchMode ? 1 : 0).shake(hz: 2),
          if (widget.isFrozen && widget.frozenSecondsRemaining != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.frozenSecondsRemaining}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate(target: _isClutchMode ? 1 : 0).boxShadow(
          begin: const BoxShadow(color: Colors.transparent),
          end: BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        );
  }
}