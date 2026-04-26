
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class LetterGrid extends StatefulWidget {
  final List<String> letters;
  final int gridSize;
  final List<int> selectedIndices;
  final List<int>? disabledIndices;
  final Map<int, int>? multipliers;
  final Function(int) onLetterTap;
  final Function(List<int>)? onSwipeComplete;
  final bool isEnabled;
  final bool requireAdjacent; // NEW: Toggle adjacent requirement

  const LetterGrid({
    super.key,
    required this.letters,
    this.gridSize = 7,
    required this.selectedIndices,
    this.disabledIndices,
    this.multipliers,
    required this.onLetterTap,
    this.onSwipeComplete,
    this.isEnabled = true,
    this.requireAdjacent = false, // DEFAULT: Allow any selection
  });

  @override
  State<LetterGrid> createState() => _LetterGridState();
}

class _LetterGridState extends State<LetterGrid> {
  List<int> _swipeSelectedIndices = [];
  bool _isSwiping = false;
  Offset? _lastPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.isEnabled ? _onPanStart : null,
      onPanUpdate: widget.isEnabled ? _onPanUpdate : null,
      onPanEnd: widget.isEnabled ? _onPanEnd : null,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.gridSize,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: widget.gridSize * widget.gridSize,
            itemBuilder: (context, index) => _buildLetterTile(context, index),
          ),
        ),
      ),
    );
  }

  Widget _buildLetterTile(BuildContext context, int index) {
    final isSelected = widget.selectedIndices.contains(index) ||
        _swipeSelectedIndices.contains(index);
    final isDisabled = widget.disabledIndices?.contains(index) ?? false;
    final multiplier = widget.multipliers?[index];
    final letter = index < widget.letters.length ? widget.letters[index] : '';

    // Determine selection order for display
    int? selectionOrder;
    if (widget.selectedIndices.contains(index)) {
      selectionOrder = widget.selectedIndices.indexOf(index) + 1;
    } else if (_swipeSelectedIndices.contains(index)) {
      selectionOrder = _swipeSelectedIndices.indexOf(index) + 1;
    }

    // Colors based on state
    Color tileColor;
    Color textColor;
    Color borderColor;

    if (isDisabled) {
      tileColor = Colors.grey.shade800;
      textColor = Colors.grey;
      borderColor = Colors.grey.shade700;
    } else if (isSelected) {
      tileColor = Theme.of(context).colorScheme.primary;
      textColor = Colors.white;
      borderColor = Theme.of(context).colorScheme.primary.withOpacity(0.8);
    } else {
      tileColor = Theme.of(context).cardColor;
      textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
      borderColor = Colors.transparent;
    }

    // Multiplier border color
    Color? multiplierBorderColor;
    if (multiplier != null && multiplier > 1 && !isDisabled) {
      multiplierBorderColor = multiplier == 2 ? Colors.blue : Colors.orange;
    }

    return GestureDetector(
      onTap: widget.isEnabled && !isDisabled
          ? () async {
              // Haptic feedback
              try {
                await Haptics.vibrate(HapticsType.light);
              } catch (_) {}
              widget.onLetterTap(index);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: multiplierBorderColor ?? borderColor,
            width: multiplierBorderColor != null ? 3 : (isSelected ? 2 : 1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main letter
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontSize: isSelected ? 24 : 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              child: Text(isDisabled ? '💣' : letter),
            ),

            // Multiplier badge (top-right)
            if (multiplier != null && multiplier > 1 && !isDisabled)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: multiplier == 2 ? Colors.blue : Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${multiplier}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Selection order badge (bottom-left)
            if (selectionOrder != null)
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$selectionOrder',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Disabled overlay
            if (isDisabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      )
          .animate(target: isSelected ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: const Duration(milliseconds: 100),
          )
          .then()
          .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1.02, 1.02),
            duration: const Duration(milliseconds: 50),
          ),
    );
  }

  // ============ SWIPE SELECTION ============

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isSwiping = true;
      _swipeSelectedIndices.clear();
      _lastPosition = details.localPosition;
    });
    _selectAtPosition(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isSwiping) return;
    _lastPosition = details.localPosition;
    _selectAtPosition(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isSwiping && _swipeSelectedIndices.isNotEmpty) {
      // Notify parent of swipe selection
      widget.onSwipeComplete?.call(List.from(_swipeSelectedIndices));
    }
    setState(() {
      _isSwiping = false;
      _swipeSelectedIndices.clear();
    });
  }

  void _selectAtPosition(Offset position) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    final padding = 8.0; // Match container padding
    final gridSize = size.width - (padding * 2);
    final cellSize = gridSize / widget.gridSize;

    // Adjust for padding
    final adjustedX = position.dx - padding;
    final adjustedY = position.dy - padding;

    final col = (adjustedX / cellSize).floor();
    final row = (adjustedY / cellSize).floor();

    // Bounds check
    if (col < 0 || col >= widget.gridSize || row < 0 || row >= widget.gridSize) {
      return;
    }

    final index = row * widget.gridSize + col;

    // Check if disabled
    if (widget.disabledIndices?.contains(index) ?? false) {
      return;
    }

    // Check if already selected in this swipe
    if (_swipeSelectedIndices.contains(index)) {
      // Allow deselecting the last selected letter
      if (_swipeSelectedIndices.isNotEmpty && _swipeSelectedIndices.last == index) {
        // Don't deselect during swipe - only on tap
      }
      return;
    }

    // NEW: Check adjacency only if required
    if (widget.requireAdjacent && _swipeSelectedIndices.isNotEmpty) {
      if (!_isAdjacent(_swipeSelectedIndices.last, index)) {
        return;
      }
    }

    // Add to selection
    setState(() {
      _swipeSelectedIndices.add(index);
    });

    // Haptic feedback
    try {
      Haptics.vibrate(HapticsType.light);
    } catch (_) {}
  }

  bool _isAdjacent(int index1, int index2) {
    final row1 = index1 ~/ widget.gridSize;
    final col1 = index1 % widget.gridSize;
    final row2 = index2 ~/ widget.gridSize;
    final col2 = index2 % widget.gridSize;

    final rowDiff = (row1 - row2).abs();
    final colDiff = (col1 - col2).abs();

    // Adjacent means within 1 step in any direction (including diagonal)
    return rowDiff <= 1 && colDiff <= 1 && !(rowDiff == 0 && colDiff == 0);
  }
}