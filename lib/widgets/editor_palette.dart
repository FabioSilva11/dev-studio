import 'package:flutter/material.dart';

import '../models/editor_project.dart';

const double _paletteWidth = 120;
const double _rowHeight = 34;
const double _rowRadius = 4;
const double _sectionGap = 4;

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
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTopTab(
                      active: !showFavoritePalette,
                      icon: Icons.widgets_outlined,
                      onTap: () => onToggleFavorite(false),
                    ),
                  ),
                  Expanded(
                    child: _buildTopTab(
                      active: showFavoritePalette,
                      icon: Icons.bookmark_border,
                      onTap: () => onToggleFavorite(true),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom widget creator is not available yet.')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE3E3EA)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 32, color: Color(0xFF56565F)),
                      SizedBox(height: 6),
                      Text(
                        'Create a widget',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF56565F)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
                      children: [
                        _buildPaletteSection('Layouts', const [
                          _PaletteItem(EditorWidgetType.linearLayout, 'Linear(H)'),
                          _PaletteItem(EditorWidgetType.linearLayout, 'Linear(V)'),
                          _PaletteItem(EditorWidgetType.horizontalScroll, 'Scroll(H)'),
                          _PaletteItem(EditorWidgetType.scrollView, 'Scroll(V)'),
                          _PaletteItem(EditorWidgetType.radioGroup, 'RadioGroup'),
                          _PaletteItem(EditorWidgetType.relativeLayout, 'RelativeLayout'),
                        ]),
                        _buildPaletteSection('AndroidX', const [
                          _PaletteItem(EditorWidgetType.tabLayout, 'TabLayout'),
                          _PaletteItem(EditorWidgetType.bottomNavigation, 'BottomNavigationView'),
                          _PaletteItem(EditorWidgetType.collapsingToolbar, 'CollapsingToolbar'),
                          _PaletteItem(EditorWidgetType.cardView, 'CardView'),
                          _PaletteItem(EditorWidgetType.textInputLayout, 'TextInputLayout'),
                          _PaletteItem(EditorWidgetType.swipeRefresh, 'SwipeRefreshLayout'),
                        ]),
                        _buildPaletteSection('Widgets', const [
                          _PaletteItem(EditorWidgetType.textView, 'TextView'),
                          _PaletteItem(EditorWidgetType.editText, 'EditText'),
                          _PaletteItem(EditorWidgetType.autoCompleteText, 'AutoCompleteTextView'),
                          _PaletteItem(EditorWidgetType.multiAutoCompleteText, 'MultiAutoCompleteTextView'),
                          _PaletteItem(EditorWidgetType.button, 'Button'),
                          _PaletteItem(EditorWidgetType.materialButton, 'MaterialButton'),
                          _PaletteItem(EditorWidgetType.imageView, 'ImageView'),
                          _PaletteItem(EditorWidgetType.circleImageView, 'CircleImageView'),
                          _PaletteItem(EditorWidgetType.checkBox, 'CheckBox'),
                          _PaletteItem(EditorWidgetType.radioButton, 'RadioButton'),
                          _PaletteItem(EditorWidgetType.switchView, 'Switch'),
                          _PaletteItem(EditorWidgetType.seekBar, 'SeekBar'),
                          _PaletteItem(EditorWidgetType.progressBar, 'ProgressBar'),
                          _PaletteItem(EditorWidgetType.ratingBar, 'RatingBar'),
                          _PaletteItem(EditorWidgetType.searchView, 'SearchView'),
                          _PaletteItem(EditorWidgetType.webView, 'WebView'),
                        ]),
                        _buildPaletteSection('Lists', const [
                          _PaletteItem(EditorWidgetType.listView, 'ListView'),
                          _PaletteItem(EditorWidgetType.gridView, 'GridView'),
                          _PaletteItem(EditorWidgetType.recyclerView, 'RecyclerView'),
                          _PaletteItem(EditorWidgetType.spinner, 'Spinner'),
                          _PaletteItem(EditorWidgetType.viewPager, 'ViewPager'),
                        ]),
                        _buildPaletteSection('Library', const [
                          _PaletteItem(EditorWidgetType.lottieAnimation, 'LottieAnimation'),
                          _PaletteItem(EditorWidgetType.otpView, 'OTPView'),
                          _PaletteItem(EditorWidgetType.codeView, 'CodeView'),
                          _PaletteItem(EditorWidgetType.patternLock, 'PatternLockView'),
                          _PaletteItem(EditorWidgetType.waveSideBar, 'WaveSideBar'),
                          _PaletteItem(EditorWidgetType.badgeView, 'BadgeView'),
                          _PaletteItem(EditorWidgetType.signInButton, 'SignInButton'),
                        ]),
                        _buildPaletteSection('Date & Time', const [
                          _PaletteItem(EditorWidgetType.calendarView, 'CalendarView'),
                          _PaletteItem(EditorWidgetType.datePicker, 'DatePicker'),
                          _PaletteItem(EditorWidgetType.timePicker, 'TimePicker'),
                          _PaletteItem(EditorWidgetType.analogClock, 'AnalogClock'),
                          _PaletteItem(EditorWidgetType.digitalClock, 'DigitalClock'),
                        ]),
                        _buildPaletteSection('Other', const [
                          _PaletteItem(EditorWidgetType.floatingButton, 'Floating Button'),
                          _PaletteItem(EditorWidgetType.mapView, 'MapView'),
                          _PaletteItem(EditorWidgetType.adView, 'AdView'),
                          _PaletteItem(EditorWidgetType.youtubePlayer, 'YoutubePlayer'),
                          _PaletteItem(EditorWidgetType.videoView, 'VideoView'),
                        ]),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTab({
    required bool active,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? accentColor : Colors.transparent,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        child: Icon(icon, size: 22, color: active ? Colors.white : const Color(0xFF8E8E93)),
      ),
    );
  }

  Widget _buildPaletteSection(String label, List<_PaletteItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 5),
          child: Text(
            label,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        for (final item in items) ...[
          _buildDraggablePaletteRow(item),
          const SizedBox(height: _sectionGap),
        ],
      ],
    );
  }

  Widget _buildDraggablePaletteRow(_PaletteItem item) {
    final row = _PaletteRow(item: item, accentColor: accentColor);
    return LongPressDraggable<EditorWidgetType>(
      data: item.type,
      delay: const Duration(milliseconds: 120),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: _paletteWidth - 8,
          child: Opacity(opacity: 0.65, child: row),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.30, child: row),
      child: row,
    );
  }
}

class _PaletteItem {
  const _PaletteItem(this.type, this.label);

  final EditorWidgetType type;
  final String label;
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.item, required this.accentColor});

  final _PaletteItem item;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0F6),
        borderRadius: BorderRadius.circular(_rowRadius),
      ),
      child: Row(
        children: [
          Icon(iconForWidget(item.type), color: const Color(0xFF5C5C66), size: 18),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1,
                color: Color(0xFF56565F),
              ),
            ),
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
