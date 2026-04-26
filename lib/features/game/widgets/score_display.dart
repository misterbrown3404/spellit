import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScoreDisplay extends StatefulWidget {
  final int score;
  final bool isDoublePoints;
  final String? playerName;
  final bool isOpponent;

  const ScoreDisplay({
    super.key,
    required this.score,
    this.isDoublePoints = false,
    this.playerName,
    this.isOpponent = false,
  });

  @override
  State<ScoreDisplay> createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends State<ScoreDisplay> {
  int _previousScore = 0;
  bool _showScoreIncrease = false;
  int _scoreIncrease = 0;

  @override
  void didUpdateWidget(ScoreDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score > oldWidget.score) {
      setState(() {
        _scoreIncrease = widget.score - oldWidget.score;
        _showScoreIncrease = true;
        _previousScore = oldWidget.score;
      });
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showScoreIncrease = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOpponent
        ? Colors.red
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: widget.isDoublePoints
            ? Border.all(color: Colors.purple, width: 2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.playerName != null) ...[
            CircleAvatar(
              radius: 10,
              backgroundColor: color,
              child: Text(
                widget.playerName![0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.playerName != null)
                  Text(
                    widget.playerName!,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.score}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    
                    // Double points indicator
                    if (widget.isDoublePoints)
                      Container(
                        margin: const EdgeInsets.only(left: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '2x',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(),
                    
                    // Score increase animation
                    if (_showScoreIncrease)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '+$_scoreIncrease',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.5).then().fadeOut(delay: 1000.ms),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}