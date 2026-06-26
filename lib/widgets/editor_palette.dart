import 'package:flutter/material.dart';

import '../models/editor_project.dart';

const double _paletteWidth = 100;
const double _tileHeight = 54;
const double _tileRadius = 9;
const double _tileGap = 5;

class EditorPalette extends StatelessWidget {
  const EditorPalette({
    super.key,
    required this.showFavoritePalette,
    required this.onToggleFavorite,
    required this.accentColor,
  });

  final bool showFavoritePalette;
  final ValueChanged<bool> onToggleFavorite;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: SizedBox(
        width: _paletteWidth,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 7, 6, 5),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: IconButton.filledTonal(
                        onPressed: () => onToggleFavorite(false),
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: !showFavoritePalette
                              ? const Color(0xFFEDE9FE)
                              : const Color(0xFFF2F2F7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        icon: const Icon(Icons.widgets_outlined, size: 19),
                        tooltip: 'Basic widgets',
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: IconButton.filledTonal(
                        onPressed: () => onToggleFavorite(true),
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: showFavoritePalette
                              ? const Color(0xFFEDE9FE)
                              : const Color(0xFFF2F2F7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        icon: const Icon(Icons.bookmark_border, size: 19),
                        tooltip: 'Favorite widgets',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom widget creator is not available yet.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size.fromHeight(40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Flexible(
                  child: Text(
                    'New widget',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
              ),
            ),
            const Divider(height: 9),
            Expanded(
              child: showFavoritePalette
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'No favorite widgets',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 18),
                      children: [
                        _buildPaletteSection('Layouts', const [
                          EditorWidgetType.linearLayout,
                          EditorWidgetType.relativeLayout,
                          EditorWidgetType.horizontalScroll,
                          EditorWidgetType.scrollView,
                          EditorWidgetType.cardView,
                          EditorWidgetType.textInputLayout,
                          EditorWidgetType.swipeRefresh,
                        ]),
                        _buildPaletteSection('Widgets', const [
                          EditorWidgetType.textView,
                          EditorWidgetType.editText,
                          EditorWidgetType.button,
                          EditorWidgetType.materialButton,
                          EditorWidgetType.imageView,
                          EditorWidgetType.circleImageView,
                          EditorWidgetType.checkBox,
                          EditorWidgetType.radioButton,
                          EditorWidgetType.radioGroup,
                          EditorWidgetType.switchView,
                          EditorWidgetType.seekBar,
                          EditorWidgetType.progressBar,
                          EditorWidgetType.ratingBar,
                          EditorWidgetType.searchView,
                          EditorWidgetType.webView,
                          EditorWidgetType.autoCompleteText,
                          EditorWidgetType.multiAutoCompleteText,
                        ]),
                        _buildPaletteSection('Lists', const [
                          EditorWidgetType.listView,
                          EditorWidgetType.gridView,
                          EditorWidgetType.recyclerView,
                          EditorWidgetType.spinner,
                          EditorWidgetType.viewPager,
                          EditorWidgetType.tabLayout,
                          EditorWidgetType.bottomNavigation,
                        ]),
                        _buildPaletteSection('Library', const [
                          EditorWidgetType.lottieAnimation,
                          EditorWidgetType.otpView,
                          EditorWidgetType.codeView,
                          EditorWidgetType.patternLock,
                          EditorWidgetType.waveSideBar,
                          EditorWidgetType.badgeView,
                          EditorWidgetType.signInButton,
                        ]),
                        _buildPaletteSection('Date & Time', const [
                          EditorWidgetType.calendarView,
                          EditorWidgetType.datePicker,
                          EditorWidgetType.timePicker,
                          EditorWidgetType.analogClock,
                          EditorWidgetType.digitalClock,
                        ]),
                        _buildPaletteSection('Other', const [
                          EditorWidgetType.floatingButton,
                          EditorWidgetType.mapView,
                          EditorWidgetType.adView,
                          EditorWidgetType.youtubePlayer,
                          EditorWidgetType.videoView,
                        ]),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteSection(String label, List<EditorWidgetType> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 9, 4, 5),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final type in types) ...[
          _buildDraggablePaletteTile(type),
          const SizedBox(height: _tileGap),
        ],
      ],
    );
  }

  Widget _buildDraggablePaletteTile(EditorWidgetType type) {
    final tile = _PaletteTile(type: type, accentColor: accentColor);
    return LongPressDraggable<EditorWidgetType>(
      data: type,
      delay: const Duration(milliseconds: 120),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: _paletteWidth - 12, child: Opacity(opacity: 0.55, child: tile)),
      ),
      childWhenDragging: Opacity(opacity: 0.30, child: tile),
      child: tile,
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({required this.type, required this.accentColor});

  final EditorWidgetType type;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _tileHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F2FF),
          borderRadius: BorderRadius.circular(_tileRadius),
          border: Border.all(color: const Color(0xFFE3DEFF)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconForWidget(type), color: accentColor, size: 21),
              const SizedBox(height: 3),
              Flexible(
                child: Text(
                  type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9.6, height: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData iconForWidget(EditorWidgetType type) {
  return switch (type) {
    EditorWidgetType.linearLayout => Icons.view_agenda_outlined,
    EditorWidgetType.relativeLayout => Icons.dashboard_outlined,
    EditorWidgetType.horizontalScroll => Icons.swap_horiz,
    EditorWidgetType.button => Icons.smart_button_outlined,
    EditorWidgetType.textView => Icons.text_fields,
    EditorWidgetType.editText => Icons.edit_note,
    EditorWidgetType.imageView => Icons.image_outlined,
    EditorWidgetType.webView => Icons.language,
    EditorWidgetType.progressBar => Icons.hourglass_top,
    EditorWidgetType.listView => Icons.view_list,
    EditorWidgetType.spinner => Icons.arrow_drop_down_circle_outlined,
    EditorWidgetType.checkBox => Icons.check_box_outlined,
    EditorWidgetType.scrollView => Icons.swap_vert,
    EditorWidgetType.switchView => Icons.toggle_on_outlined,
    EditorWidgetType.seekBar => Icons.tune,
    EditorWidgetType.calendarView => Icons.calendar_month_outlined,
    EditorWidgetType.floatingButton => Icons.add_circle_outline,
    EditorWidgetType.adView => Icons.ads_click,
    EditorWidgetType.mapView => Icons.map_outlined,
    EditorWidgetType.radioButton => Icons.radio_button_checked,
    EditorWidgetType.ratingBar => Icons.star_border,
    EditorWidgetType.videoView => Icons.video_library_outlined,
    EditorWidgetType.searchView => Icons.search,
    EditorWidgetType.autoCompleteText ||
    EditorWidgetType.multiAutoCompleteText => Icons.manage_search,
    EditorWidgetType.gridView => Icons.grid_view,
    EditorWidgetType.analogClock ||
    EditorWidgetType.digitalClock => Icons.schedule,
    EditorWidgetType.datePicker ||
    EditorWidgetType.timePicker => Icons.event_outlined,
    EditorWidgetType.tabLayout => Icons.tab,
    EditorWidgetType.viewPager => Icons.view_carousel_outlined,
    EditorWidgetType.bottomNavigation => Icons.space_bar,
    EditorWidgetType.badgeView => Icons.badge_outlined,
    EditorWidgetType.patternLock => Icons.pattern,
    EditorWidgetType.waveSideBar => Icons.waves,
    EditorWidgetType.cardView => Icons.crop_16_9,
    EditorWidgetType.collapsingToolbar => Icons.vertical_align_top,
    EditorWidgetType.textInputLayout => Icons.input,
    EditorWidgetType.swipeRefresh => Icons.refresh,
    EditorWidgetType.radioGroup => Icons.radio_button_checked,
    EditorWidgetType.materialButton => Icons.smart_button,
    EditorWidgetType.signInButton => Icons.login,
    EditorWidgetType.circleImageView => Icons.account_circle_outlined,
    EditorWidgetType.lottieAnimation => Icons.animation,
    EditorWidgetType.youtubePlayer => Icons.play_circle_outline,
    EditorWidgetType.otpView => Icons.password,
    EditorWidgetType.codeView => Icons.code,
    EditorWidgetType.recyclerView => Icons.view_stream_outlined,
  };
}
