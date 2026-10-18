part of 'library_page_widgets.dart';

// 库页搜索框（输入、提交与同步）：#311 part 拆分。
class LibrarySearchField extends ConsumerStatefulWidget {
  const LibrarySearchField({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<LibrarySearchField> createState() => _LibrarySearchFieldState();
}

class _LibrarySearchFieldState extends ConsumerState<LibrarySearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kLibrarySearchMaxWidth),
        child: CustomTextField(
          controller: _controller,
          hintText: l10n.librarySearchHint,
          onSubmitted: _handleSubmitSearch,
        ),
      ),
    );
  }

  void _handleSubmitSearch(String value) {
    final String query = value.trim();
    if (query.isEmpty) {
      showInfoToast(context, context.l10n.librarySearchKeywordEmpty);
      return;
    }
    final String encodedQuery = Uri.encodeQueryComponent(query);
    ref.read(appRouterProvider).push('/searched?q=$encodedQuery');
  }
}
