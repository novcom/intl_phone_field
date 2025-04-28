import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/helpers.dart';

class PickerDialogStyle {
  final Color? backgroundColor;

  final TextStyle? countryCodeStyle;

  final TextStyle? countryNameStyle;

  final Widget? listTileDivider;

  final EdgeInsets? listTilePadding;

  final EdgeInsets? padding;

  final Color? searchFieldCursorColor;

  final InputDecoration? searchFieldInputDecoration;

  final EdgeInsets? searchFieldPadding;

  final double? width;
  final double? height;

  PickerDialogStyle({
    this.backgroundColor,
    this.countryCodeStyle,
    this.countryNameStyle,
    this.listTileDivider,
    this.listTilePadding,
    this.padding,
    this.searchFieldCursorColor,
    this.searchFieldInputDecoration,
    this.searchFieldPadding,
    this.width,
    this.height,
  });
}

class CountryPickerDialog extends StatefulWidget {
  final List<Country> countryList;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;
  final String searchText;
  final List<Country> filteredCountries;
  final PickerDialogStyle? style;
  final String languageCode;

  const CountryPickerDialog({
    Key? key,
    required this.searchText,
    required this.languageCode,
    required this.countryList,
    required this.onCountryChanged,
    required this.selectedCountry,
    required this.filteredCountries,
    this.style,
  }) : super(key: key);

  @override
  State<CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<CountryPickerDialog> {
  late List<Country> _filteredCountries;
  late Country _selectedCountry;
  late List<Country> _pinnedCountries;

  @override
  void initState() {
    _selectedCountry = widget.selectedCountry;

    _pinnedCountries = widget.filteredCountries.take(6).toList();

    final rest = widget.filteredCountries.skip(6).toList()..sort((a, b) => a.localizedName(widget.languageCode).compareTo(b.localizedName(widget.languageCode)));

    _filteredCountries = [..._pinnedCountries, ...rest];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final width = widget.style?.width ?? mediaWidth;
    final height = widget.style?.height ?? 24.0;
    const defaultHorizontalPadding = 40.0;
    const defaultVerticalPadding = 24.0;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(vertical: height, horizontal: mediaWidth > (width + defaultHorizontalPadding * 2) ? (mediaWidth - width) / 2 : defaultHorizontalPadding),
      backgroundColor: widget.style?.backgroundColor,
      child: Container(
        padding: widget.style?.padding ?? const EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Padding(
              padding: widget.style?.searchFieldPadding ?? const EdgeInsets.all(0),
              child: TextField(
                cursorColor: widget.style?.searchFieldCursorColor,
                decoration: widget.style?.searchFieldInputDecoration ??
                    InputDecoration(
                      suffixIcon: const Icon(Icons.search),
                      labelText: widget.searchText,
                    ),
                onChanged: (value) {
                  final searchResult = widget.countryList.stringSearch(value);

                  // Extract matches excluding pinned
                  final unpinnedResults = searchResult.where((c) => !_pinnedCountries.contains(c)).toList()
                    ..sort((a, b) => a.localizedName(widget.languageCode).compareTo(b.localizedName(widget.languageCode)));

                  // Add pinned countries if they match the search
                  final matchingPinned =
                      _pinnedCountries.where((c) => c.localizedName(widget.languageCode).toLowerCase().contains(value.toLowerCase()) || c.dialCode.contains(value)).toList();

                  _filteredCountries = [...matchingPinned, ...unpinnedResults];
                  if (mounted) setState(() {});
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCountries.length,
                itemBuilder: (ctx, index) {
                  final country = _filteredCountries[index];

                  final isSeparatorIndex = index == _pinnedCountries.length &&
                      _filteredCountries.length > _pinnedCountries.length &&
                      _filteredCountries.sublist(0, _pinnedCountries.length).every((c) => _pinnedCountries.contains(c));
                  final isLastPinnedBeforeSeparator = index == _pinnedCountries.length - 1 &&
                      _filteredCountries.length > _pinnedCountries.length &&
                      _filteredCountries.sublist(0, _pinnedCountries.length).every((c) => _pinnedCountries.contains(c));

                  return Column(
                    children: <Widget>[
                      if (isSeparatorIndex)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            color: Colors.grey.shade200,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(child: Divider(thickness: 2)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    getLocalizedOtherCountriesLabel(widget.languageCode),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black54,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(thickness: 2)),
                              ],
                            ),
                          ),
                        ),
                      ListTile(
                        leading: kIsWeb
                            ? Image.asset(
                                'assets/flags/${country.code.toLowerCase()}.png',
                                package: 'intl_phone_field',
                                width: 32,
                              )
                            : Text(
                                country.flag,
                                style: const TextStyle(fontSize: 18),
                              ),
                        contentPadding: widget.style?.listTilePadding,
                        title: Text(
                          country.localizedName(widget.languageCode),
                          style: widget.style?.countryNameStyle ?? const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: Text(
                          '+${country.dialCode}',
                          style: widget.style?.countryCodeStyle ?? const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onTap: () {
                          _selectedCountry = country;
                          widget.onCountryChanged(_selectedCountry);
                          Navigator.of(context).pop();
                        },
                      ),
                      isLastPinnedBeforeSeparator ? Container() : widget.style?.listTileDivider ?? const Divider(thickness: 1),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getLocalizedOtherCountriesLabel(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'it': // Italy
        return 'Altri paesi';
      case 'ro': // Romania
        return 'Alte țări';
      case 'de': // Germany, Austria, Switzerland, Liechtenstein
        return 'Weitere Länder';
      case 'fr': // France, French-speaking Switzerland/Lux.
        return 'Autres pays';
      case 'en': // English
      default:
        return 'Other countries';
    }
  }
}
