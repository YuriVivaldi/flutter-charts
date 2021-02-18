part of flutter_charts;

/// Item painter, use [barPainter] or [barPainter].
/// Custom painter can also be added by extending [GeometryPainter]
typedef ChartGeometryPainter<T> = GeometryPainter<T> Function(ChartItem<T> item, ChartState state);

/// Bar painter
GeometryPainter<T> barPainter<T>(ChartItem<T> item, ChartState<T> state) => BarGeometryPainter<T>(item, state);

/// Bubble painter
GeometryPainter<T> bubblePainter<T>(ChartItem<T> item, ChartState<T> state) => BubbleGeometryPainter<T>(item, state);

/// Main state of the charts. Painter will use this as state and it will format chart depending
/// on options.
///
/// [options] Modifiers for chart
///
/// [itemOptions] Contains all modifiers for separate bar item
///
/// [foregroundDecorations] and [backgroundDecorations] decorations that aren't connected directly to the
/// chart but can show important info (Axis, target line...)
///
/// More different decorations can be added by extending [DecorationPainter]
class ChartState<T> {
  ChartState(
    this.data, {
    this.options = const ChartOptions(),
    this.itemOptions = const ChartItemOptions(),
    this.behaviour = const ChartBehaviour(),
    this.backgroundDecorations = const <DecorationPainter>[],
    this.foregroundDecorations = const <DecorationPainter>[],
    this.geometryPainter = barPainter,
  })  : assert(data.isNotEmpty, 'No items!'),
        assert((options?.padding?.vertical ?? 0.0) == 0.0, 'Chart padding cannot be vertical!') {
    /// Set default padding and margin, decorations padding and margins will be added to this value
    defaultPadding = options?.padding ?? EdgeInsets.zero;
    defaultMargin = EdgeInsets.zero;
    _setUpDecorations();
  }

  ChartState._lerp(
    this.data, {
    this.options = const ChartOptions(),
    this.itemOptions = const ChartItemOptions(),
    this.behaviour = const ChartBehaviour(),
    this.backgroundDecorations = const [],
    this.foregroundDecorations = const [],
    this.defaultMargin,
    this.defaultPadding,
    this.geometryPainter = barPainter,
  }) {
    _initDecorations();
  }

  /// Data
  final ChartData<T> data;

  /// Geometry
  final ChartGeometryPainter geometryPainter;

  /// Theme
  final ChartOptions options;
  final ChartItemOptions itemOptions;
  final ChartBehaviour behaviour;
  // Theme Decorations
  final List<DecorationPainter> backgroundDecorations;
  final List<DecorationPainter> foregroundDecorations;

  /// Margin of chart drawing area where items are drawn. This is so decorations
  /// can be placed outside of the chart drawing area without actually scaling the chart.
  EdgeInsets defaultMargin;

  /// Padding is used for decorations that want other decorations to be drawn on them.
  /// Unlike [defaultMargin] decorations can draw inside the padding area.
  EdgeInsets defaultPadding;

  List<DecorationPainter> get allDecorations => [...foregroundDecorations, ...backgroundDecorations];

  /// Set up decorations and calculate chart's [defaultPadding] and [defaultMargin]
  /// Decorations are a bit special, calling init on them with current state
  /// this is required because some decorations need to know some stuff about chart
  /// before being able to tell how much padding or/and margin do they need in order to lay them out properly
  ///
  /// First init decoration, this will make sure that all decorations are able to calculate their
  /// margin and padding needed
  ///
  /// Add all calculated paddings and margins for current decorations in this state
  /// they will update [defaultMargin] and [defaultPadding] values
  void _setUpDecorations() {
    _initDecorations();
    _getDecorationsPadding();
    _getDecorationsMargin();
  }

  /// Init all decorations, pass current chart state so each decoration can access data it requires
  /// to set up it's padding and margin values
  void _initDecorations() => allDecorations.forEach((decoration) => decoration.initDecoration(this));

  /// Get total padding needed by all decorations
  void _getDecorationsMargin() => allDecorations.forEach((element) => defaultMargin += element.marginNeeded());

  /// Get total margin needed by all decorations
  void _getDecorationsPadding() => allDecorations.forEach((element) => defaultPadding += element.paddingNeeded());

  /// For later in case charts will have to animate between states.
  static ChartState<T> lerp<T>(ChartState<T> a, ChartState<T> b, double t) {
    return ChartState<T>._lerp(
      ChartData.lerp(a.data, b.data, t),
      options: ChartOptions.lerp(a.options, b.options, t),
      behaviour: ChartBehaviour.lerp(a.behaviour, b.behaviour, t),
      itemOptions: ChartItemOptions.lerp(a.itemOptions, b.itemOptions, t),
      // Find background matches, if found, then animate to them, else just show them.
      backgroundDecorations: b.backgroundDecorations.map((e) {
        final DecorationPainter _match =
            a.backgroundDecorations.firstWhere((element) => element.isSameType(e), orElse: () => null);
        if (_match != null) {
          return _match.animateTo(e, t);
        }

        return e;
      }).toList(),
      // Find foreground matches, if found, then animate to them, else just show them.
      foregroundDecorations: b.foregroundDecorations.map((e) {
        final DecorationPainter _match =
            a.foregroundDecorations.firstWhere((element) => element.isSameType(e), orElse: () => null);
        if (_match != null) {
          return _match.animateTo(e, t);
        }

        return e;
      }).toList(),

      defaultMargin: EdgeInsets.lerp(a.defaultMargin, b.defaultMargin, t),
      defaultPadding: EdgeInsets.lerp(a.defaultPadding, b.defaultPadding, t),

      // Lerp missing
      geometryPainter: t < 0.5 ? a.geometryPainter : b.geometryPainter,
    );
  }
}
