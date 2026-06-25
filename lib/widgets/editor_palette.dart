import 'package:flutter/material.dart';
import '../models/editor_project.dart';

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
        width: 118,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 8, 7, 5),
              child: Row(
                children: [
                  Expanded(
                    child: IconButton.filledTonal(
                      onPressed: () => onToggleFavorite(false),
                      style: IconButton.styleFrom(
                        backgroundColor: !showFavoritePalette
                            ? const Color(0xFFEDE9FE)
                            : const Color(0xFFF2F2F7),
                      ),
                      icon: const Icon(Icons.widgets_outlined, size: 20),
                      tooltip: 'Basic widgets',
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: IconButton.filledTonal(
                      onPressed: () => onToggleFavorite(true),
                      style: IconButton.styleFrom(
                        backgroundColor: showFavoritePalette
                            ? const Color(0xFFEDE9FE)
                            : const Color(0xFFF2F2F7),
                      ),
                      icon: const Icon(Icons.bookmark_border, size: 20),
                      tooltip: 'Favorite widgets',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom widget creator is not available yet.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size.fromHeight(42),
                ),
                icon: const Icon(Icons.add, size: 17),
                label: const Flexible(
                  child: Text(
                    'New widget',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
            const Divider(height: 10),
            Expanded(
              child: showFavoritePalette
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'No favorite widgets',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(7, 0, 7, 18),
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
                          EditorWidgetType.switchView,
                          EditorWidgetType.seekBar,
                          EditorWidgetType.progressBar,
                          EditorWidgetType.ratingBar,
                          EditorWidgetType.searchView,
                          EditorWidgetType.webView,
                        ]),
                        _buildPaletteSection('Lists', const [
                          EditorWidgetType.listView,
                          EditorWidgetType.gridView,
                          EditorWidgetType.recyclerView,
                          EditorWidgetType.spinner,
                          EditorWidgetType.viewPager,
                        ]),
                        _buildPaletteSection('Library', const [
                          EditorWidgetType.lottieAnimation,
                          EditorWidgetType.otpView,
                          EditorWidgetType.codeView,
                          EditorWidgetType.patternLock,
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
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 5),
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
          const SizedBox(height: 6),
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
        child: Opacity(opacity: 0.5, child: tile),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: tile),
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
    return Container(
      width: 104,
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3DEFF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconForWidget(type), color: accentColor, size: 24),
          const SizedBox(height: 4),
          Text(
            type.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        ],
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
